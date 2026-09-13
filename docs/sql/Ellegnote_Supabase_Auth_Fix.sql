-- ==============================================================================
-- Ellegnote — Auto-Confirm Email Fix for Seamless Face ID & Mobile Login
-- Run this in Supabase Dashboard > SQL Editor.
-- ==============================================================================

-- 1. Potvrdiť všetkých existujúcich používateľov (vrátane tvojho účtu)
-- V novších verziách Supabase je "confirmed_at" generovaný stĺpec,
-- preto sa nastavuje iba "email_confirmed_at".
UPDATE auth.users
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    raw_app_meta_data = raw_app_meta_data || '{"provider":"email","providers":["email"]}'::jsonb
WHERE email_confirmed_at IS NULL;

-- 2. Automatický trigger pre každú novú registráciu:
-- Automaticky nastaví email_confirmed_at pri vytvorení používateľa,
-- takže tanečníci nemusia čakať na potvrdzovací email a môžu sa okamžite prihlásiť.
CREATE OR REPLACE FUNCTION public.auto_confirm_new_users()
RETURNS trigger AS $$
BEGIN
    NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Zmazať starý trigger ak existoval a vytvoriť nový
DROP TRIGGER IF EXISTS on_auth_user_created_auto_confirm ON auth.users;

CREATE TRIGGER on_auth_user_created_auto_confirm
BEFORE INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.auto_confirm_new_users();
