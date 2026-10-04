-- ==============================================================================
-- 🎫 ENCORE - APPLE WALLET PASSES & SECURE INVITE TOKENS MIGRATION
-- ==============================================================================

-- 1. Doplnenie stĺpcov do PROFILES (KSIS ID, tanečné skupiny a card_theme)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS ksis_id TEXT,
ADD COLUMN IF NOT EXISTS dancer_groups JSONB DEFAULT '["Štandardné tance", "Latinskoamerické tance"]'::jsonb,
ADD COLUMN IF NOT EXISTS card_theme JSONB DEFAULT '{"theme_id": "carmine_gold", "background_color": "rgb(102, 3, 18)", "foreground_color": "rgb(255, 230, 153)", "label_color": "rgb(212, 175, 55)", "logo_text": "ENCORE"}'::jsonb;

-- 2. Tabuľka INVITE_TOKENS (Náhodné, nehádateľné, expirovateľné tokeny pre QR kódy a Universal linky)
CREATE TABLE IF NOT EXISTS public.invite_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invite_tokens_token ON public.invite_tokens(token);
CREATE INDEX IF NOT EXISTS idx_invite_tokens_user ON public.invite_tokens(user_id);

-- RLS pre INVITE_TOKENS
ALTER TABLE public.invite_tokens ENABLE ROW LEVEL SECURITY;

-- Vlastník vidí a spravuje svoje tokeny
CREATE POLICY "invite_tokens_owner_all" ON public.invite_tokens
FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- 3. Tabuľka PASS_REGISTRATIONS (Pre oficiálnu Apple PassKit Web Service registráciu zariadení)
CREATE TABLE IF NOT EXISTS public.pass_registrations (
    device_library_identifier TEXT NOT NULL,
    pass_type_identifier TEXT NOT NULL,
    serial_number TEXT NOT NULL,
    push_token TEXT NOT NULL,
    authorization_token TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (device_library_identifier, pass_type_identifier, serial_number)
);

ALTER TABLE public.pass_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pass_registrations_owner_select" ON public.pass_registrations
FOR SELECT TO authenticated
USING (auth.uid() = user_id);


-- 4. RPC Funkcia: Vytvorenie / Obnovenie náhodného bezpečného pozvánkového tokenu
CREATE OR REPLACE FUNCTION public.create_friend_invite_token(p_expires_in_days INT DEFAULT 7)
RETURNS TEXT AS $$
DECLARE
    new_token TEXT;
    caller_id UUID := auth.uid();
BEGIN
    IF caller_id IS NULL THEN
        RAISE EXCEPTION 'Neautorizovaný prístup.';
    END IF;

    -- Zneplatniť predchádzajúce aktívne tokeny tohto používateľa (aby platil vždy najnovší QR kód)
    UPDATE public.invite_tokens
    SET revoked_at = now()
    WHERE user_id = caller_id AND revoked_at IS NULL;

    -- Vygenerovať bezpečný náhodný reťazec (32 hex znakov s prefixom tok_)
    new_token := 'tok_' || encode(gen_random_bytes(16), 'hex');

    INSERT INTO public.invite_tokens (user_id, token, expires_at)
    VALUES (caller_id, new_token, now() + (p_expires_in_days || ' days')::interval);

    RETURN new_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. RPC Funkcia: Bezpečný náhľad pozvánky (Vráti len verejné info, žiadne emaily ani interné UUID)
CREATE OR REPLACE FUNCTION public.get_friend_invite_preview(p_token TEXT)
RETURNS JSONB AS $$
DECLARE
    v_token RECORD;
    v_profile RECORD;
    v_caller UUID := auth.uid();
    v_is_self BOOLEAN := FALSE;
    v_already_connected BOOLEAN := FALSE;
    v_pending BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_token
    FROM public.invite_tokens
    WHERE token = p_token;

    IF v_token IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'NOT_FOUND', 'message', 'Pozvánka neexistuje.');
    END IF;

    IF v_token.revoked_at IS NOT NULL THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'REVOKED', 'message', 'Tento QR kód bol zrušený a obnovený novým.');
    END IF;

    IF v_token.expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'EXPIRED', 'message', 'Platnosť tohto QR kódu vypršala.');
    END IF;

    IF v_caller IS NOT NULL AND v_caller = v_token.user_id THEN
        v_is_self := TRUE;
    END IF;

    IF v_caller IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1 FROM public.connections 
            WHERE ((user_a_id = v_caller AND user_b_id = v_token.user_id) 
                OR (user_a_id = v_token.user_id AND user_b_id = v_caller))
              AND status = 'accepted'
        ) INTO v_already_connected;

        SELECT EXISTS (
            SELECT 1 FROM public.connections 
            WHERE ((user_a_id = v_caller AND user_b_id = v_token.user_id) 
                OR (user_a_id = v_token.user_id AND user_b_id = v_caller))
              AND status = 'pending'
        ) INTO v_pending;
    END IF;

    SELECT full_name, club, avatar_url, ksis_id, dancer_code, dancer_groups, card_theme
    INTO v_profile
    FROM public.profiles
    WHERE id = v_token.user_id;

    RETURN jsonb_build_object(
        'success', true,
        'is_self', v_is_self,
        'already_connected', v_already_connected,
        'is_pending', v_pending,
        'inviter', jsonb_build_object(
            'name', COALESCE(v_profile.full_name, 'Tanečník Encore'),
            'club', COALESCE(v_profile.club, 'Individuálny'),
            'avatar_url', v_profile.avatar_url,
            'ksis_id', v_profile.ksis_id,
            'dancer_code', COALESCE(v_profile.dancer_code, 'DNC-0000'),
            'dancer_groups', COALESCE(v_profile.dancer_groups, '["Štandard", "Latina"]'::jsonb),
            'card_theme', v_profile.card_theme
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 6. RPC Funkcia: Prijatie alebo Odmietnutie pozvánky
CREATE OR REPLACE FUNCTION public.respond_to_friend_invite(p_token TEXT, p_accept BOOLEAN)
RETURNS JSONB AS $$
DECLARE
    v_token RECORD;
    v_caller UUID := auth.uid();
    v_existing_conn RECORD;
BEGIN
    IF v_caller IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'UNAUTHORIZED', 'message', 'Musíš byť prihlásený.');
    END IF;

    SELECT * INTO v_token
    FROM public.invite_tokens
    WHERE token = p_token;

    IF v_token IS NULL OR v_token.revoked_at IS NOT NULL OR v_token.expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_TOKEN', 'message', 'Pozvánka je neplatná alebo expirovala.');
    END IF;

    IF v_caller = v_token.user_id THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'SELF_INVITE', 'message', 'Nemôžeš potvrdiť pozvánku sám sebe.');
    END IF;

    -- Skontrolovať či už spojenie neexistuje
    SELECT * INTO v_existing_conn
    FROM public.connections
    WHERE (user_a_id = v_caller AND user_b_id = v_token.user_id AND relationship_type = 'partner')
       OR (user_a_id = v_token.user_id AND user_b_id = v_caller AND relationship_type = 'partner');

    IF p_accept THEN
        IF v_existing_conn IS NOT NULL THEN
            UPDATE public.connections
            SET status = 'accepted', updated_at = now()
            WHERE id = v_existing_conn.id;
        ELSE
            INSERT INTO public.connections (user_a_id, user_b_id, relationship_type, status, initiated_by)
            VALUES (v_token.user_id, v_caller, 'partner', 'accepted', v_caller);
        END IF;

        RETURN jsonb_build_object('success', true, 'status', 'accepted', 'message', 'Pozvánka bola úspešne prijatá.');
    ELSE
        IF v_existing_conn IS NOT NULL AND v_existing_conn.status = 'pending' THEN
            UPDATE public.connections
            SET status = 'rejected', updated_at = now()
            WHERE id = v_existing_conn.id;
        END IF;

        RETURN jsonb_build_object('success', true, 'status', 'rejected', 'message', 'Pozvánka bola odmietnutá.');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
