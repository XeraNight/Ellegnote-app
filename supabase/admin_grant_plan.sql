-- ==============================================================================
-- ENCORE — Owner: give a user a plan (Plus / Studio) or take it away
-- Run in Supabase Dashboard -> SQL Editor. Edit the 3 values in the first block only.
-- (The SQL editor has no logged-in user, so the in-app RPC would say FORBIDDEN here;
--  this writes the table directly. The in-app Owner console does the same job.)
-- ==============================================================================

-- 1) Who exists? (find the exact e-mail first)
-- SELECT id, email, created_at FROM auth.users ORDER BY created_at;

-- 2) Grant. tier: 'free' | 'plus' | 'studio'.   months: NULL = no expiry.
WITH params AS (
  SELECT
    'friend@example.com'::text AS target_email,   -- <-- CHANGE
    'plus'::text               AS tier,           -- <-- CHANGE: free | plus | studio
    NULL::int                  AS months,         -- <-- CHANGE: e.g. 3, or NULL
    'Dar od majiteľa'::text    AS note
),
target AS (
  SELECT u.id FROM auth.users u, params p WHERE lower(u.email) = lower(trim(p.target_email))
),
owner AS (
  SELECT id FROM auth.users WHERE lower(email) = 'jakubkalina05@gmail.com'
)
INSERT INTO public.user_entitlements (user_id, tier, source, expires_at, granted_by, notes, updated_at)
SELECT t.id,
       p.tier,
       'owner_grant',
       CASE WHEN p.months IS NULL THEN NULL ELSE now() + make_interval(months => p.months) END,
       (SELECT id FROM owner),
       p.note,
       now()
FROM target t, params p
ON CONFLICT (user_id) DO UPDATE SET
  tier       = EXCLUDED.tier,
  source     = 'owner_grant',
  expires_at = EXCLUDED.expires_at,
  granted_by = EXCLUDED.granted_by,
  notes      = EXCLUDED.notes,
  updated_at = now()
RETURNING user_id, tier, expires_at;
-- 0 rows returned = that e-mail has not registered yet.

-- 3) Overview of everyone who has a plan
-- SELECT u.email, e.tier, e.source, e.expires_at, e.notes
-- FROM public.user_entitlements e JOIN auth.users u ON u.id = e.user_id
-- ORDER BY e.updated_at DESC;

-- 4) Take a plan away (back to Free)
-- DELETE FROM public.user_entitlements
--  WHERE user_id = (SELECT id FROM auth.users WHERE lower(email) = lower('friend@example.com'));
