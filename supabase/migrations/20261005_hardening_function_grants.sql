-- ==============================================================================
-- ENCORE — Hardening: function grants, search_path, StoreKit RPC, stale invites
-- Project: iukblwlttvrcdclmlyxu ("Ellegnote app")   Date: 2026-10-05
-- Safe to run more than once. Paste into Supabase Dashboard -> SQL Editor -> Run.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Trigger-only functions must not be callable through the REST API (/rpc/...).
--    Triggers keep working: EXECUTE is checked when a trigger is created, not when it fires.
-- ------------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.auto_confirm_new_users()           FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.check_user_couples_max_limit()     FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_user_platform_sync()        FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.protect_profile_privileged_columns() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.set_profile_invite_code()          FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()                  FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. Friend requests need a signed-in user (the function already rejects anon,
--    but it should not even be reachable).
--    NOT touched on purpose: get_friend_invite_preview (anon needs it for invite links).
-- ------------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.send_friend_request_by_code(TEXT) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.send_friend_request_by_code(TEXT) TO authenticated;

-- ------------------------------------------------------------------------------
-- 3. Pin search_path on functions that had none (fixes 3 linter warnings).
-- ------------------------------------------------------------------------------
ALTER FUNCTION public.auto_confirm_new_users()       SET search_path = public;
ALTER FUNCTION public.check_user_couples_max_limit() SET search_path = public;
ALTER FUNCTION public.generate_unique_invite_code()  SET search_path = public;

-- ------------------------------------------------------------------------------
-- 4. IMPORTANT: record_app_store_transaction trusts the tier sent by the client.
--    Any signed-in user could call it with p_tier = 'studio' and give themselves
--    Studio for free. The app only uses it to mirror a purchase (the real check
--    runs on-device with StoreKit), and it already ignores a failure, so close it.
--    Re-open later via an Edge Function that verifies App Store Server Notifications.
-- ------------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.record_app_store_transaction(TEXT, TEXT, TIMESTAMPTZ)
  FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 5. Housekeeping: dead invite tokens (revoked or expired) can never be used again.
--    The app creates a new token on every open, so they pile up (282 of 284 were dead).
-- ------------------------------------------------------------------------------
DELETE FROM public.invite_tokens
 WHERE revoked_at IS NOT NULL OR expires_at < now();

COMMIT;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- LATER, before real users (do NOT run now):
--
-- A) Real e-mail verification. Right now EVERY sign-up is auto-confirmed by trigger
--    on_auth_user_created_auto_confirm, so the e-mail is never actually checked.
--    Only run this once Dashboard -> Authentication -> SMTP (e.g. Resend) works and
--    "Confirm email" is switched ON, otherwise nobody can sign up:
--
--      DROP TRIGGER IF EXISTS on_auth_user_created_auto_confirm ON auth.users;
--
-- B) Dashboard -> Authentication -> Providers -> Email: set minimum password length
--    to 8+ and enable "Leaked password protection" (may need the Pro plan).
-- ==============================================================================
