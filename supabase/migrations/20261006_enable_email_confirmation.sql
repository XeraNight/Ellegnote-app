-- ==============================================================================
-- ENCORE — Turn on REAL e-mail verification   (Date: 2026-10-06)
--
-- DO NOT RUN THIS YET. Run it only after ALL of these are done in the Dashboard:
--   [ ] Authentication -> Providers -> Email: "Confirm email" is ON
--   [ ] Authentication -> SMTP Settings: custom SMTP (e.g. Resend) works; send yourself a test
--   [ ] Authentication -> Email Templates: "Confirm sign up" and "Reset password" contain
--       {{ .Token }} (copy from supabase/templates/confirmation.html and recovery.html)
--   [ ] Authentication -> URL Configuration: Site URL is NOT localhost, Redirect URLs
--       contains encore://auth-callback
--   [ ] The app build with the 6-digit code screen (this repo) is what testers run
--
-- Why: the trigger below confirms every new e-mail automatically, so nothing is ever verified.
-- That allows pre-account takeover: someone registers a victim's address, and later the victim
-- signs in with Google/Apple using the same address. With verification on, Supabase removes
-- unconfirmed identities when it links a verified one.
--
-- If you run it too early nobody can finish registering (the confirmation mail never arrives).
-- Rollback (the function stays in the database, only the trigger is removed here):
--   CREATE TRIGGER on_auth_user_created_auto_confirm BEFORE INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_new_users();
-- ==============================================================================

BEGIN;

DROP TRIGGER IF EXISTS on_auth_user_created_auto_confirm ON auth.users;
-- The function is kept for the rollback; nobody can call it (privileges were revoked in 20261005).

COMMIT;

-- Accounts created while auto-confirm was active stay confirmed. Review them:
--   SELECT email, created_at FROM auth.users ORDER BY created_at;
