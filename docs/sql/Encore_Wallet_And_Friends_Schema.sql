-- ==============================================================================
-- Encore: Apple Wallet Pass, Profiles, Invite Codes & Friendship System
-- Run this in Supabase Dashboard > SQL Editor
-- This script is 100% idempotent and self-contained (creates profiles if missing)
-- ==============================================================================

begin;

-- 1. Ensure public.profiles table exists with all required columns
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    name text,
    club text default 'Encore Dance Club',
    avatar_url text,
    invite_code text unique,
    platform text default 'unknown',
    last_platform text default 'unknown',
    client_type text default 'unknown',
    app_version text,
    last_sign_in_at timestamptz default now(),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Ensure all columns exist even if table was partially created previously
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists name text;
alter table public.profiles add column if not exists club text default 'Encore Dance Club';
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists invite_code text;
alter table public.profiles add column if not exists platform text default 'unknown';
alter table public.profiles add column if not exists last_platform text default 'unknown';
alter table public.profiles add column if not exists client_type text default 'unknown';
alter table public.profiles add column if not exists app_version text;
alter table public.profiles add column if not exists last_sign_in_at timestamptz default now();
alter table public.profiles add column if not exists created_at timestamptz default now();
alter table public.profiles add column if not exists updated_at timestamptz default now();

-- Ensure unique index on invite_code
create unique index if not exists idx_profiles_invite_code on public.profiles(invite_code);

-- 2. Enable Row Level Security on profiles
alter table public.profiles enable row level security;

-- Drop existing policies to allow clean reruns
drop policy if exists "encore_profiles_select_own" on public.profiles;
drop policy if exists "encore_profiles_insert_own" on public.profiles;
drop policy if exists "encore_profiles_update_own" on public.profiles;
drop policy if exists "encore_profiles_select_by_invite" on public.profiles;

-- Users can view and manage their own profile
create policy "encore_profiles_select_own"
on public.profiles for select
to authenticated
using (auth.uid() = id);

create policy "encore_profiles_insert_own"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

create policy "encore_profiles_update_own"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Allow reading name, club, avatar_url & invite_code when looking up an invite (public & authenticated)
create policy "encore_profiles_select_by_invite"
on public.profiles for select
to anon, authenticated
using (invite_code is not null);

-- 3. Automatic user sync from auth.users to public.profiles
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
    v_platform      := coalesce(new.raw_user_meta_data->>'platform', 'ios');
    v_last_platform := coalesce(new.raw_user_meta_data->>'last_platform', v_platform);
    v_client_type   := coalesce(new.raw_user_meta_data->>'client_type', 'ios_native');
    v_name          := coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1));
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

drop trigger if exists on_auth_user_created_or_updated on auth.users;
create trigger on_auth_user_created_or_updated
after insert or update on auth.users
for each row execute function public.handle_user_platform_sync();

-- 4. Backfill existing auth.users into profiles table
insert into public.profiles (id, email, name, platform, last_platform, client_type, last_sign_in_at, created_at, updated_at)
select 
    id,
    email,
    coalesce(raw_user_meta_data->>'name', raw_user_meta_data->>'full_name', split_part(email, '@', 1)),
    coalesce(raw_user_meta_data->>'platform', 'ios'),
    coalesce(raw_user_meta_data->>'last_platform', 'ios'),
    coalesce(raw_user_meta_data->>'client_type', 'ios_native'),
    coalesce(last_sign_in_at, created_at),
    created_at,
    now()
from auth.users
on conflict (id) do nothing;

-- 5. Helper function: Generate an unambiguous 8-character invite code
-- Alphabet excludes confusing characters: 0, O, 1, I, L
create or replace function public.generate_unique_invite_code()
returns text
language plpgsql
as $$
declare
    v_alphabet text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    v_alphabet_len int := length(v_alphabet);
    v_code text;
    v_exists boolean;
    v_i int;
begin
    loop
        v_code := '';
        for v_i in 1..8 loop
            v_code := v_code || substr(v_alphabet, floor(random() * v_alphabet_len + 1)::int, 1);
        end loop;
        
        select exists(select 1 from public.profiles where invite_code = v_code) into v_exists;
        exit when not v_exists;
    end loop;
    return v_code;
end;
$$;

-- 6. Trigger: Automatically assign an invite_code when a profile is created/updated
create or replace function public.set_profile_invite_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.invite_code is null or trim(new.invite_code) = '' then
        new.invite_code := public.generate_unique_invite_code();
    else
        new.invite_code := upper(trim(new.invite_code));
    end if;
    return new;
end;
$$;

drop trigger if exists tr_set_profile_invite_code on public.profiles;
create trigger tr_set_profile_invite_code
before insert or update on public.profiles
for each row
when (new.invite_code is null or trim(new.invite_code) = '')
execute function public.set_profile_invite_code();

-- 7. Backfill invite_code for all existing profiles
do $$
declare
    r record;
begin
    for r in select id from public.profiles where invite_code is null or trim(invite_code) = '' loop
        update public.profiles
        set invite_code = public.generate_unique_invite_code()
        where id = r.id;
    end loop;
end;
$$;

-- 8. Create public.friends table
create table if not exists public.friends (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    friend_id uuid not null references auth.users(id) on delete cascade,
    status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint unique_friendship unique (user_id, friend_id)
);

create index if not exists idx_friends_user_id on public.friends(user_id);
create index if not exists idx_friends_friend_id on public.friends(friend_id);

-- 9. Enable Row Level Security on public.friends
alter table public.friends enable row level security;

drop policy if exists "friends_select_own" on public.friends;
drop policy if exists "friends_insert_own" on public.friends;
drop policy if exists "friends_update_own" on public.friends;
drop policy if exists "friends_delete_own" on public.friends;

create policy "friends_select_own"
on public.friends for select
to authenticated
using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_insert_own"
on public.friends for insert
to authenticated
with check (auth.uid() = user_id);

create policy "friends_update_own"
on public.friends for update
to authenticated
using (auth.uid() = user_id or auth.uid() = friend_id)
with check (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_delete_own"
on public.friends for delete
to authenticated
using (auth.uid() = user_id or auth.uid() = friend_id);

-- 10. Secure RPC: send_friend_request_by_code
-- Allows authenticated user to send a friend request using only an invite code (never exposes raw user_id in QR)
create or replace function public.send_friend_request_by_code(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_caller_id uuid := auth.uid();
    v_target_profile record;
    v_existing_friendship record;
    v_reverse_request record;
    v_clean_code text := upper(trim(p_invite_code));
begin
    if v_caller_id is null then
        return jsonb_build_object(
            'success', false,
            'error', 'unauthenticated',
            'message', 'Na odoslanie žiadosti musíš byť prihlásený.'
        );
    end if;

    -- Lookup target profile by invite code
    select id, name, invite_code
    into v_target_profile
    from public.profiles
    where invite_code = v_clean_code;

    if not found then
        return jsonb_build_object(
            'success', false,
            'error', 'invalid_code',
            'message', 'Kód pozvánky je neplatný alebo vypršal.'
        );
    end if;

    -- Cannot add yourself
    if v_target_profile.id = v_caller_id then
        return jsonb_build_object(
            'success', false,
            'error', 'self_invite',
            'message', 'Nemôžeš pridať seba samého ako priateľa.'
        );
    end if;

    -- Check if reverse request exists (auto-accept)
    select id, status
    into v_reverse_request
    from public.friends
    where user_id = v_target_profile.id and friend_id = v_caller_id;

    if found then
        if v_reverse_request.status = 'pending' then
            update public.friends
            set status = 'accepted', updated_at = now()
            where id = v_reverse_request.id;

            return jsonb_build_object(
                'success', true,
                'status', 'accepted',
                'auto_accepted', true,
                'message', format('Priateľstvo s %s bolo potvrdené!', coalesce(v_target_profile.name, 'tanečníkom')),
                'friend_id', v_target_profile.id,
                'friend_name', v_target_profile.name
            );
        elsif v_reverse_request.status = 'accepted' then
            return jsonb_build_object(
                'success', true,
                'status', 'accepted',
                'message', format('S %s už ste priateľmi.', coalesce(v_target_profile.name, 'tanečníkom')),
                'friend_id', v_target_profile.id,
                'friend_name', v_target_profile.name
            );
        end if;
    end if;

    -- Check existing forward request
    select id, status
    into v_existing_friendship
    from public.friends
    where user_id = v_caller_id and friend_id = v_target_profile.id;

    if found then
        return jsonb_build_object(
            'success', true,
            'status', v_existing_friendship.status,
            'message', case
                when v_existing_friendship.status = 'accepted' then format('S %s už ste priateľmi.', coalesce(v_target_profile.name, 'tanečníkom'))
                else 'Žiadosť o priateľstvo už bola odoslaná.'
            end,
            'friend_id', v_target_profile.id,
            'friend_name', v_target_profile.name
        );
    end if;

    -- Insert new pending friendship request
    insert into public.friends (user_id, friend_id, status)
    values (v_caller_id, v_target_profile.id, 'pending');

    return jsonb_build_object(
        'success', true,
        'status', 'pending',
        'message', format('Žiadosť o priateľstvo bola odoslaná pre %s!', coalesce(v_target_profile.name, 'tanečníka')),
        'friend_id', v_target_profile.id,
        'friend_name', v_target_profile.name
    );
end;
$$;

commit;
