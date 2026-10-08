-- generate_unique_invite_code() is only used by the trigger set_profile_invite_code().
-- It must not be callable through the REST API. The trigger keeps working: the function owner
-- (postgres) still has EXECUTE, and triggers run the function with the owner's rights.
-- Safe to run more than once.
REVOKE EXECUTE ON FUNCTION public.generate_unique_invite_code() FROM PUBLIC, anon, authenticated;
