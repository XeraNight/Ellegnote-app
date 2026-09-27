-- ==============================================================================
-- 👑 ENCORE - ADMIN, ENTITLEMENTS, MODERATION & CONNECTIONS MIGRATION
-- ==============================================================================

-- 1. Rozšírenie tabuľky PROFILES o status moderovania a roly
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'banned')),
ADD COLUMN IF NOT EXISTS ban_reason TEXT,
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'coach', 'admin', 'owner')),
ADD COLUMN IF NOT EXISTS dancer_code TEXT UNIQUE;

-- 2. Tabuľka USER_ENTITLEMENTS (Pre StoreKit a manuálne VIP darovania majiteľom)
CREATE TABLE IF NOT EXISTS public.user_entitlements (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('free', 'plus', 'studio')),
    source TEXT NOT NULL CHECK (source IN ('storekit', 'owner_grant', 'promo_vip')),
    expires_at TIMESTAMPTZ, -- NULL = Doživotne (Lifetime)
    granted_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS pre USER_ENTITLEMENTS
ALTER TABLE public.user_entitlements ENABLE ROW LEVEL SECURITY;

-- Používateľ vidí svoje vlastné oprávnenie
CREATE POLICY "user_entitlements_view_own" ON public.user_entitlements
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'owner');

-- Majiteľ môže vkladať a upravovať oprávnenia
CREATE POLICY "user_entitlements_owner_manage" ON public.user_entitlements
FOR ALL TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'owner')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'owner');


-- 3. Jednotná tabuľka CONNECTIONS (Partneri a Tréner-Žiak)
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Vlastník obsahu (žiak / iniciátor páru)
    user_b_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Prístupujúci (tréner / tanečný partner)
    relationship_type TEXT NOT NULL CHECK (relationship_type IN ('partner', 'coach_student')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'revoked')),
    initiated_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_a_id, user_b_id, relationship_type)
);

-- RLS pre CONNECTIONS
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "connections_user_access" ON public.connections
FOR ALL TO authenticated
USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);


-- 4. Bezpečná SQL funkcia pre vyhľadávanie tanečníkov (Žiadne vystavovanie e-mailov ani dump databázy)
CREATE OR REPLACE FUNCTION search_dancers(query TEXT)
RETURNS TABLE (
    dancer_code TEXT,
    full_name TEXT,
    club TEXT,
    avatar_url TEXT
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    IF length(trim(query)) < 2 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT p.dancer_code, p.full_name, p.club, p.avatar_url
    FROM public.profiles p
    WHERE (p.account_status IS NULL OR p.account_status = 'active')
      AND (p.dancer_code ILIKE query || '%' OR p.full_name ILIKE '%' || query || '%')
    LIMIT 10;
END;
$$;
