-- Dancer or coach: chosen at registration, changeable later in the profile.
-- This is a label ("what do you do"), not a permission. Coach powers still come only from an accepted
-- coach_student connection (see is_coach_of_routine), and `profiles.role` (owner/admin) stays protected.

alter table public.profiles
  add column if not exists dance_role text not null default 'dancer';

alter table public.profiles drop constraint if exists profiles_dance_role_check;
alter table public.profiles
  add constraint profiles_dance_role_check check (dance_role in ('dancer', 'coach'));

-- Sign-up trigger: take the role from the registration metadata (anything else becomes 'dancer').
create or replace function public.handle_user_platform_sync()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_platform text;
  v_last_platform text;
  v_client_type text;
  v_name text;
  v_app_version text;
  v_dance_role text;
begin
  v_platform      := left(coalesce(new.raw_user_meta_data->>'platform', 'ios'), 20);
  v_last_platform := left(coalesce(new.raw_user_meta_data->>'last_platform', v_platform), 20);
  v_client_type   := left(coalesce(new.raw_user_meta_data->>'client_type', 'ios_native'), 30);
  v_name          := left(btrim(coalesce(new.raw_user_meta_data->>'name',
                                         new.raw_user_meta_data->>'full_name',
                                         split_part(new.email, '@', 1))), 60);
  v_app_version   := left(new.raw_user_meta_data->>'app_version', 20);
  v_dance_role    := case when new.raw_user_meta_data->>'dance_role' = 'coach' then 'coach' else 'dancer' end;

  insert into public.profiles (id, email, name, platform, last_platform, client_type, app_version,
                               last_sign_in_at, created_at, updated_at, dance_role)
  values (new.id, new.email, v_name, v_platform, v_last_platform, v_client_type, v_app_version,
          coalesce(new.last_sign_in_at, now()), now(), now(), v_dance_role)
  on conflict (id) do update set
    email = excluded.email,
    name = coalesce(profiles.name, excluded.name),
    last_platform = case when excluded.last_platform <> 'unknown' then excluded.last_platform else profiles.last_platform end,
    client_type   = case when excluded.client_type   <> 'unknown' then excluded.client_type   else profiles.client_type   end,
    app_version = coalesce(excluded.app_version, profiles.app_version),
    last_sign_in_at = coalesce(new.last_sign_in_at, now()),
    updated_at = now();   -- dance_role is deliberately not overwritten on later sign-ins

  return new;
end;
$$;
revoke execute on function public.handle_user_platform_sync() from public, anon, authenticated;
