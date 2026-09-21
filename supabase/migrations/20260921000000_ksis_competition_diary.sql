-- ==============================================================================
-- Encore KSIS Competition Results Diary & Class Advancement Schema (Step 1)
-- All tables have Row Level Security enabled.
-- All client access (authenticated & anon) is SELECT-only.
-- All writes (insert/update/delete/soft delete/restore) happen exclusively via
-- Supabase Edge Functions using the service_role key.
-- ==============================================================================

begin;

-- ------------------------------------------------------------------------------
-- 1. Table: public.user_couples
-- Self-declaration by dancer of their registered couple IDs (max 2 per user)
-- ------------------------------------------------------------------------------
create table if not exists public.user_couples (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    couple_id integer not null,
    discipline text not null default 'ALL' check (discipline in ('STT', 'LAT', '10T', 'ALL')),
    partner_name text,
    partner_consent boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint user_couples_user_couple_unique unique (user_id, couple_id)
);

comment on table public.user_couples is 
    'Registered dancer couple IDs. NOTE: This is a self-declaration by the dancer in the Encore app, NOT proof of legal identity or ownership.';

-- Enforce max 2 registered couples per user via trigger
create or replace function public.check_user_couples_max_limit()
returns trigger
language plpgsql
security definer
as $$
begin
    if (select count(*) from public.user_couples where user_id = new.user_id) >= 2 then
        raise exception 'Maximum limit of 2 couples per user reached.';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_user_couples_max_limit on public.user_couples;
create trigger trg_user_couples_max_limit
    before insert on public.user_couples
    for each row execute function public.check_user_couples_max_limit();

-- Enable RLS
alter table public.user_couples enable row level security;

-- Drop existing policies if any
drop policy if exists "user_couples_select_own" on public.user_couples;
drop policy if exists "user_couples_insert_own" on public.user_couples;
drop policy if exists "user_couples_update_own" on public.user_couples;
drop policy if exists "user_couples_delete_own" on public.user_couples;

-- SELECT own rows only
create policy "user_couples_select_own"
on public.user_couples for select
to authenticated
using (auth.uid() = user_id);

-- Explicitly NO insert, update, or delete policies for authenticated or anon.


-- ------------------------------------------------------------------------------
-- 2. Table: public.competition_results
-- Official imported competition results diary with class advancement stats
-- ------------------------------------------------------------------------------
create table if not exists public.competition_results (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    sutaz_id integer not null,
    couple_id integer not null,
    event_name text not null,
    category_name text not null,
    discipline text not null check (discipline in ('STT', 'LAT', '10T')),
    date date not null,
    place text,
    couple_count integer not null,
    placement_text text not null,               -- e.g. "3." or "7.-9."
    placement integer,                          -- parsed numeric e.g. 3 or 7 (nullable)
    points_earned integer not null default 0,
    cumulative_stats text,                      -- raw KSIS source of truth e.g. "89/5F" (nullable)
    cumulative_points integer not null default 0,
    cumulative_finals integer not null default 0,
    crosses_count integer,                      -- parsed crosses count if present (nullable)
    is_official boolean not null default true,
    season text not null,                       -- e.g. "2025/2026"
    is_deleted boolean not null default false,  -- soft delete flag
    deleted_at timestamptz,
    imported_at timestamptz not null default now(),
    constraint competition_results_user_sutaz_couple_unique unique (user_id, sutaz_id, couple_id)
);

comment on table public.competition_results is
    'Imported official competition results from KSIS. Writes are exclusively handled by Edge Functions.';

-- Indexes for performant filtering
create index if not exists idx_comp_results_user_active on public.competition_results(user_id, is_deleted);
create index if not exists idx_comp_results_user_discipline on public.competition_results(user_id, discipline);
create index if not exists idx_comp_results_user_date on public.competition_results(user_id, date desc);

-- Enable RLS
alter table public.competition_results enable row level security;

-- Drop existing policies if any
drop policy if exists "competition_results_select_own" on public.competition_results;
drop policy if exists "competition_results_insert_own" on public.competition_results;
drop policy if exists "competition_results_update_own" on public.competition_results;
drop policy if exists "competition_results_delete_own" on public.competition_results;

-- SELECT own rows including soft-deleted (app filters out is_deleted = false, needed for restore flow)
create policy "competition_results_select_own"
on public.competition_results for select
to authenticated
using (auth.uid() = user_id);

-- Explicitly NO insert, update, or delete policies for authenticated or anon.


-- ------------------------------------------------------------------------------
-- 3. Table: public.advancement_rules
-- Advancement criteria rules from SZTŠ guidelines (never hardcoded in client)
-- ------------------------------------------------------------------------------
create table if not exists public.advancement_rules (
    id uuid primary key default gen_random_uuid(),
    category text not null,                     -- e.g. "Dospelí", "Junior I", etc.
    from_class text not null,                   -- e.g. "E", "D", "C", "B", "A"
    to_class text not null,                     -- e.g. "D", "C", "B", "A", "S"
    required_points integer not null,
    required_finals integer not null,
    notes text,
    created_at timestamptz not null default now(),
    constraint advancement_rules_cat_class_unique unique (category, from_class, to_class)
);

comment on table public.advancement_rules is
    'Class advancement requirements according to SZTŠ dance sport regulations.';

-- Enable RLS
alter table public.advancement_rules enable row level security;

-- Drop existing policies if any
drop policy if exists "advancement_rules_select_authenticated" on public.advancement_rules;
drop policy if exists "advancement_rules_insert_authenticated" on public.advancement_rules;
drop policy if exists "advancement_rules_update_authenticated" on public.advancement_rules;
drop policy if exists "advancement_rules_delete_authenticated" on public.advancement_rules;

-- SELECT for authenticated users
create policy "advancement_rules_select_authenticated"
on public.advancement_rules for select
to authenticated
using (true);

-- Seed Adults D -> C and progression classes
insert into public.advancement_rules (category, from_class, to_class, required_points, required_finals, notes)
values
    ('Dospelí', 'E', 'D', 100, 2, 'Orientačné pravidlo (verify against current SZTŠ rules).'),
    ('Dospelí', 'D', 'C', 200, 5, 'verify against current SZTŠ rules'),
    ('Dospelí', 'C', 'B', 200, 5, 'verify against current SZTŠ rules'),
    ('Dospelí', 'B', 'A', 200, 5, 'verify against current SZTŠ rules'),
    ('Dospelí', 'A', 'S', 200, 5, 'verify against current SZTŠ rules')
on conflict (category, from_class, to_class) do update
set required_points = excluded.required_points,
    required_finals = excluded.required_finals,
    notes = excluded.notes;


-- ------------------------------------------------------------------------------
-- 4. Table: public.import_cooldowns
-- Cooldown tracking table. RLS enabled, NO POLICIES (strictly service_role only)
-- ------------------------------------------------------------------------------
create table if not exists public.import_cooldowns (
    key text primary key,                       -- "user:<uuid>" or "sutaz:<id>"
    last_attempt_at timestamptz not null default now()
);

comment on table public.import_cooldowns is
    'Internal cooldown table for KSIS imports. Service role only.';

-- Enable RLS, zero policies = locked for anon & authenticated
alter table public.import_cooldowns enable row level security;


-- ------------------------------------------------------------------------------
-- 5. Atomic Rate Limiter SQL Function
-- Checks user cooldown (60 s) and competition cooldown (30 s) atomically.
-- Returns 0 if allowed (and updates timestamp atomically), or retry_after seconds.
-- ------------------------------------------------------------------------------
create or replace function public.check_and_acquire_import_cooldown(
    p_user_id uuid,
    p_sutaz_id integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_key text := 'user:' || p_user_id::text;
    v_sutaz_key text := 'sutaz:' || p_sutaz_id::text;
    v_now timestamptz := clock_timestamp();
    v_user_last timestamptz;
    v_sutaz_last timestamptz;
    v_user_wait integer := 0;
    v_sutaz_wait integer := 0;
    v_retry_after integer := 0;
begin
    -- Fetch existing rows with FOR UPDATE to serialize concurrent requests for this user/competition
    select last_attempt_at into v_user_last
    from public.import_cooldowns
    where key = v_user_key
    for update;

    if v_user_last is not null and v_user_last + interval '60 seconds' > v_now then
        v_user_wait := ceil(extract(epoch from (v_user_last + interval '60 seconds' - v_now)))::integer;
    end if;

    select last_attempt_at into v_sutaz_last
    from public.import_cooldowns
    where key = v_sutaz_key
    for update;

    if v_sutaz_last is not null and v_sutaz_last + interval '30 seconds' > v_now then
        v_sutaz_wait := ceil(extract(epoch from (v_sutaz_last + interval '30 seconds' - v_now)))::integer;
    end if;

    v_retry_after := greatest(v_user_wait, v_sutaz_wait);

    -- If cooldown active, do NOT update timestamp; return retry_after seconds
    if v_retry_after > 0 then
        return v_retry_after;
    end if;

    -- Cooldown passed: atomically UPSERT both keys with current timestamp
    insert into public.import_cooldowns (key, last_attempt_at)
    values 
        (v_user_key, v_now),
        (v_sutaz_key, v_now)
    on conflict (key) do update
    set last_attempt_at = excluded.last_attempt_at;

    return 0;
end;
$$;

-- Revoke insert, update, delete privileges from anon and authenticated on all KSIS tables
-- This provides defense-in-depth on top of Row Level Security.
revoke insert, update, delete on public.user_couples from anon, authenticated;
revoke insert, update, delete on public.competition_results from anon, authenticated;
revoke insert, update, delete on public.advancement_rules from anon, authenticated;
revoke all on public.import_cooldowns from anon, authenticated;

-- Restrict execution to service_role only
revoke all on function public.check_and_acquire_import_cooldown(uuid, integer) from public, anon, authenticated;
grant execute on function public.check_and_acquire_import_cooldown(uuid, integer) to service_role;

commit;
