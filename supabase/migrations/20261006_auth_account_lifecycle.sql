-- ==============================================================================
-- ENCORE — Auth & account lifecycle (DB side)
-- Project: iukblwlttvrcdclmlyxu ("Ellegnote app")   Date: 2026-10-06
--
-- What this does (why):
--   1. Foreign keys to auth.users no longer block account deletion (routines,
--      user_entitlements.granted_by, connections.initiated_by; canvas_nodes cascades).
--   2. Profiles: server generates dancer_code, clients cannot change dancer_code /
--      invite_code / email, name and club length limits (the sign-up trigger truncates too).
--   3. Ban is enforced on the server: auth.users.banned_until + sessions deleted +
--      restrictive RLS policies, instead of a UI-only flag.
--   4. Log table for the send-email edge function (rate limiting, no raw addresses).
--   5. Drops a duplicate unique index on profiles.invite_code.
--
-- Safe to run more than once. Run in: Supabase Dashboard -> SQL Editor.
-- BEFORE running: run the verification block at the bottom ("PRE-CHECK") if you want
-- to see what will change. Test a ban/unban on a throw-away account afterwards.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Foreign keys that block deleting a user
--    (NO ACTION -> CASCADE, or SET NULL for the nullable "granted_by" audit column)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  v_action text;
BEGIN
  FOR r IN
    SELECT c.conname, c.conrelid::regclass AS tbl, a.attname AS col, a.attnotnull AS not_null
      FROM pg_constraint c
      JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
     WHERE c.contype = 'f'
       AND c.confdeltype = 'a'                      -- NO ACTION
       AND c.confrelid = 'auth.users'::regclass
       AND c.conrelid IN ('public.routines'::regclass,
                          'public.user_entitlements'::regclass,
                          'public.connections'::regclass)
  LOOP
    v_action := CASE WHEN r.col = 'granted_by' AND NOT r.not_null THEN 'SET NULL' ELSE 'CASCADE' END;
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tbl, r.conname);
    EXECUTE format(
      'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES auth.users(id) ON DELETE %s',
      r.tbl, r.conname, r.col, v_action
    );
    RAISE NOTICE 'FK % on %.% -> ON DELETE %', r.conname, r.tbl, r.col, v_action;
  END LOOP;

  -- canvas_nodes must disappear with their routine
  FOR r IN
    SELECT c.conname, a.attname AS col
      FROM pg_constraint c
      JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
     WHERE c.contype = 'f'
       AND c.conrelid = 'public.canvas_nodes'::regclass
       AND c.confrelid = 'public.routines'::regclass
       AND c.confdeltype <> 'c'
  LOOP
    EXECUTE format('ALTER TABLE public.canvas_nodes DROP CONSTRAINT %I', r.conname);
    EXECUTE format(
      'ALTER TABLE public.canvas_nodes ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.routines(id) ON DELETE CASCADE',
      r.conname, r.col
    );
    RAISE NOTICE 'FK % on canvas_nodes.% -> ON DELETE CASCADE', r.conname, r.col;
  END LOOP;
END $$;

-- ------------------------------------------------------------------------------
-- 2a. Sign-up trigger must never fail because of a long name (it would block sign-up)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_user_platform_sync()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_platform text;
  v_last_platform text;
  v_client_type text;
  v_name text;
  v_app_version text;
BEGIN
  v_platform      := left(coalesce(new.raw_user_meta_data->>'platform', 'ios'), 20);
  v_last_platform := left(coalesce(new.raw_user_meta_data->>'last_platform', v_platform), 20);
  v_client_type   := left(coalesce(new.raw_user_meta_data->>'client_type', 'ios_native'), 30);
  v_name          := left(btrim(coalesce(new.raw_user_meta_data->>'name',
                                         new.raw_user_meta_data->>'full_name',
                                         split_part(new.email, '@', 1))), 60);
  v_app_version   := left(new.raw_user_meta_data->>'app_version', 20);

  INSERT INTO public.profiles (id, email, name, platform, last_platform, client_type, app_version,
                               last_sign_in_at, created_at, updated_at)
  VALUES (new.id, new.email, v_name, v_platform, v_last_platform, v_client_type, v_app_version,
          coalesce(new.last_sign_in_at, now()), now(), now())
  ON CONFLICT (id) DO UPDATE SET
    email = excluded.email,
    name = coalesce(profiles.name, excluded.name),
    last_platform = CASE WHEN excluded.last_platform <> 'unknown' THEN excluded.last_platform ELSE profiles.last_platform END,
    client_type   = CASE WHEN excluded.client_type   <> 'unknown' THEN excluded.client_type   ELSE profiles.client_type   END,
    app_version = coalesce(excluded.app_version, profiles.app_version),
    last_sign_in_at = coalesce(new.last_sign_in_at, now()),
    updated_at = now();

  RETURN new;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.handle_user_platform_sync() FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2b. Length limits (existing rows are trimmed first so the constraint can be validated)
-- ------------------------------------------------------------------------------
UPDATE public.profiles SET name = left(name, 60) WHERE name IS NOT NULL AND char_length(name) > 60;
UPDATE public.profiles SET club = left(club, 80) WHERE club IS NOT NULL AND char_length(club) > 80;

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_name_len;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_name_len CHECK (name IS NULL OR char_length(name) <= 60);
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_club_len;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_club_len CHECK (club IS NULL OR char_length(club) <= 80);

-- ------------------------------------------------------------------------------
-- 2c. dancer_code is generated on the server (6 digits for new users, old 4-digit codes stay)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_dancer_code()
RETURNS text LANGUAGE plpgsql VOLATILE SET search_path = public AS $$
DECLARE
  c text;
  tries int := 0;
BEGIN
  LOOP
    c := 'DNC-' || lpad((floor(random() * 900000) + 100000)::int::text, 6, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE dancer_code = c);
    tries := tries + 1;
    IF tries > 25 THEN
      RAISE EXCEPTION 'Dancer ID could not be generated';
    END IF;
  END LOOP;
  RETURN c;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.generate_dancer_code() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.profiles_fill_server_defaults()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.dancer_code IS NULL THEN
    NEW.dancer_code := public.generate_dancer_code();
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.profiles_fill_server_defaults() FROM PUBLIC, anon, authenticated;

-- Named so it fires AFTER trg_protect_profile_privileged (triggers run alphabetically).
DROP TRIGGER IF EXISTS trg_zz_profiles_server_defaults ON public.profiles;
CREATE TRIGGER trg_zz_profiles_server_defaults
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.profiles_fill_server_defaults();

-- Backfill (runs without a JWT, so the protection trigger lets it through)
UPDATE public.profiles SET dancer_code = public.generate_dancer_code() WHERE dancer_code IS NULL;

-- ------------------------------------------------------------------------------
-- 2d. Protect privileged and identity columns from the client
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_privileged_columns()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Service role / postgres / auth triggers have no JWT user
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    NEW.role := 'user';
    NEW.account_status := 'active';
    NEW.ban_reason := NULL;
    NEW.dancer_code := NULL;            -- generated by trg_zz_profiles_server_defaults
    RETURN NEW;
  END IF;

  IF public.is_app_owner() THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role
     OR NEW.account_status IS DISTINCT FROM OLD.account_status
     OR NEW.ban_reason IS DISTINCT FROM OLD.ban_reason THEN
    RAISE EXCEPTION 'Zmena roly alebo stavu účtu nie je povolená.' USING ERRCODE = '42501';
  END IF;

  IF NEW.dancer_code IS DISTINCT FROM OLD.dancer_code AND OLD.dancer_code IS NOT NULL THEN
    RAISE EXCEPTION 'Dancer ID sa nedá meniť.' USING ERRCODE = '42501';
  END IF;

  IF NEW.invite_code IS DISTINCT FROM OLD.invite_code AND OLD.invite_code IS NOT NULL THEN
    RAISE EXCEPTION 'Kód pozvánky sa nedá meniť.' USING ERRCODE = '42501';
  END IF;

  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'E-mail sa mení cez nastavenia účtu, nie cez profil.' USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.protect_profile_privileged_columns() FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 3. Ban enforced on the server
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_account_active()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = auth.uid()
       AND p.account_status IN ('banned', 'suspended')
  );
$$;
REVOKE EXECUTE ON FUNCTION public.is_account_active() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.is_account_active() TO authenticated;

-- A banned user keeps a valid JWT for up to an hour; these policies cut data access immediately.
-- profiles stays readable so the app can show the "account blocked" notice.
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['routines', 'canvas_nodes', 'figure_library_items', 'connections',
                           'friends', 'invite_tokens', 'user_couples', 'competition_results']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS active_account_only ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY active_account_only ON public.%I AS RESTRICTIVE FOR ALL TO authenticated '
      'USING ((SELECT public.is_account_active())) WITH CHECK ((SELECT public.is_account_active()))',
      t
    );
  END LOOP;
END $$;

DROP POLICY IF EXISTS active_account_only ON storage.objects;
CREATE POLICY active_account_only ON storage.objects AS RESTRICTIVE FOR ALL TO authenticated
  USING (bucket_id <> 'encore-media' OR (SELECT public.is_account_active()))
  WITH CHECK (bucket_id <> 'encore-media' OR (SELECT public.is_account_active()));

CREATE OR REPLACE FUNCTION public.admin_set_account_status(
  p_user UUID,
  p_banned BOOLEAN,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_app_owner() THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'FORBIDDEN',
                              'message', 'Nemáš oprávnenie majiteľa aplikácie.');
  END IF;

  IF p_user = auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'SELF',
                              'message', 'Nemôžeš zablokovať vlastný účet.');
  END IF;

  UPDATE public.profiles
     SET account_status = CASE WHEN p_banned THEN 'banned' ELSE 'active' END,
         ban_reason     = CASE WHEN p_banned THEN left(p_reason, 300) ELSE NULL END
   WHERE id = p_user;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'NOT_FOUND');
  END IF;

  IF p_banned THEN
    -- GoTrue refuses sign-in and token refresh for banned users; killing sessions ends them now.
    UPDATE auth.users SET banned_until = now() + interval '100 years' WHERE id = p_user;
    DELETE FROM auth.sessions WHERE user_id = p_user;
  ELSE
    UPDATE auth.users SET banned_until = NULL WHERE id = p_user;
  END IF;

  RETURN jsonb_build_object('success', true, 'banned', p_banned);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_set_account_status(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.admin_set_account_status(UUID, BOOLEAN, TEXT) TO authenticated;

-- ------------------------------------------------------------------------------
-- 4. Rate-limit log for the send-email edge function (service role only, no policies)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.email_send_log (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind       TEXT NOT NULL,
  to_hash    TEXT NOT NULL,                 -- sha-256 of the lower-cased recipient, never the address
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_email_send_log_user_time ON public.email_send_log (user_id, created_at DESC);
ALTER TABLE public.email_send_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.email_send_log FROM anon, authenticated;

-- ------------------------------------------------------------------------------
-- 5. Duplicate unique index (profiles_invite_code_key already enforces uniqueness)
-- ------------------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_profiles_invite_code;

COMMIT;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- VERIFY (run after the migration; every query should look as described)
-- ==============================================================================
-- a) No more NO ACTION foreign keys to auth.users in public tables:
--    SELECT conrelid::regclass, conname FROM pg_constraint
--     WHERE contype='f' AND confrelid='auth.users'::regclass AND confdeltype='a'
--       AND connamespace='public'::regnamespace;                       -- expect 0 rows
-- b) Every profile has a dancer code:
--    SELECT count(*) FROM public.profiles WHERE dancer_code IS NULL;    -- expect 0
-- c) Ban round trip on a TEST account (replace the id), then check auth.users.banned_until:
--    (call from the app's Owner console, or in SQL with the owner's JWT claims)
-- d) Policies present:
--    SELECT tablename, policyname FROM pg_policies WHERE policyname='active_account_only';
