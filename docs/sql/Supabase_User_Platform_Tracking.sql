-- ==============================================================================
-- Ellegnote — User Platform Tracking & Profiles Schema (iOS vs Web)
-- Run this in Supabase Dashboard > SQL Editor.
-- ==============================================================================

begin;

-- 1. Create public.profiles table to track user client origin and activity
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    name text,
    platform text default 'unknown',         -- Initial registration platform: 'ios' | 'web'
    last_platform text default 'unknown',    -- Last active sign-in platform: 'ios' | 'web'
    client_type text default 'unknown',      -- 'ios_native' | 'web_companion'
    app_version text,
    last_sign_in_at timestamptz default now(),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- 2. Enable Row Level Security
alter table public.profiles enable row level security;

-- 3. Drop existing policies if any to allow safe re-runs
drop policy if exists "ellegnote_profiles_select_own" on public.profiles;
drop policy if exists "ellegnote_profiles_insert_own" on public.profiles;
drop policy if exists "ellegnote_profiles_update_own" on public.profiles;

-- 4. RLS Policies (Users can read and update their own profile)
create policy "ellegnote_profiles_select_own"
on public.profiles for select
to authenticated
using (auth.uid() = id);

create policy "ellegnote_profiles_insert_own"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

create policy "ellegnote_profiles_update_own"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- 5. Trigger Function to automatically sync auth.users metadata to public.profiles
create or replace function public.handle_user_platform_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_platform text;
    v_last_platform text;
    v_client_type text;
    v_name text;
    v_app_version text;
begin
    -- Extract platform metadata from raw_user_meta_data JSON
    v_platform      := coalesce(new.raw_user_meta_data->>'platform', 'unknown');
    v_last_platform := coalesce(new.raw_user_meta_data->>'last_platform', v_platform);
    v_client_type   := coalesce(new.raw_user_meta_data->>'client_type', 'unknown');
    v_name          := coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
    v_app_version   := new.raw_user_meta_data->>'app_version';

    insert into public.profiles (
        id,
        email,
        name,
        platform,
        last_platform,
        client_type,
        app_version,
        last_sign_in_at,
        created_at,
        updated_at
    )
    values (
        new.id,
        new.email,
        v_name,
        v_platform,
        v_last_platform,
        v_client_type,
        v_app_version,
        coalesce(new.last_sign_in_at, now()),
        now(),
        now()
    )
    on conflict (id) do update set
        email = excluded.email,
        name = coalesce(excluded.name, profiles.name),
        last_platform = case 
            when excluded.last_platform <> 'unknown' then excluded.last_platform 
            else profiles.last_platform 
        end,
        client_type = case 
            when excluded.client_type <> 'unknown' then excluded.client_type 
            else profiles.client_type 
        end,
        app_version = coalesce(excluded.app_version, profiles.app_version),
        last_sign_in_at = coalesce(new.last_sign_in_at, now()),
        updated_at = now();

    return new;
end;
$$;

-- 6. Attach Trigger on auth.users (fires on insert and update)
drop trigger if exists on_auth_user_created_or_updated on auth.users;

create trigger on_auth_user_created_or_updated
after insert or update on auth.users
for each row execute function public.handle_user_platform_sync();

-- 7. Backfill existing users into profiles table
insert into public.profiles (id, email, name, platform, last_platform, client_type, last_sign_in_at, created_at, updated_at)
select 
    id,
    email,
    coalesce(raw_user_meta_data->>'name', split_part(email, '@', 1)),
    coalesce(raw_user_meta_data->>'platform', 'legacy'),
    coalesce(raw_user_meta_data->>'last_platform', 'legacy'),
    coalesce(raw_user_meta_data->>'client_type', 'legacy'),
    coalesce(last_sign_in_at, created_at),
    created_at,
    now()
from auth.users
on conflict (id) do nothing;

commit;
