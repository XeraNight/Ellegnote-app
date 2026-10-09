-- KSIS automatic sync: link a couple by name or KSIS number, keep its class, points and finals from
-- KSIS, import results with every judge's crosses, and follow the couple live on competition day.
-- Plan: docs/KSIS_AUTO_CONNECT_PLAN.md. All KSIS reading happens in the Edge Function `ksis-sync`
-- (service role); users only read their own rows. Lock-screen push comes after the Developer account;
-- until then the app shows notifications from `user_notifications` through Realtime.

begin;

-- 1. The linked couple: what the dancer chose + the latest numbers from KSIS ----------------------
-- couple_id = KSIS internal id of par.php (found from the couple's first result; null until then).
alter table public.user_couples alter column couple_id drop not null;
alter table public.user_couples
  add column if not exists pair_number       integer,      -- KSIS "Č.pr" of the couple (the partner's personal number)
  add column if not exists person_number     integer,      -- the user's own KSIS personal number, if given
  add column if not exists partner_names     text,         -- "Partner & Partnerka" as KSIS shows them
  add column if not exists club              text,
  add column if not exists age_category      text,         -- e.g. "Dospelí"
  add column if not exists stt_class         text,
  add column if not exists stt_points        integer,
  add column if not exists stt_finals        integer,
  add column if not exists stt_class_since   date,
  add column if not exists lat_class         text,
  add column if not exists lat_points        integer,
  add column if not exists lat_finals        integer,
  add column if not exists lat_class_since   date,
  add column if not exists ksis_refreshed_at timestamptz,
  add column if not exists live_tracking     boolean not null default true;

create unique index if not exists user_couples_user_pair_unique
  on public.user_couples (user_id, pair_number) where pair_number is not null;

-- 2. Results: rounds with every judge's marks, the judges, start number ----------------------------
alter table public.competition_results
  add column if not exists start_number text,
  add column if not exists rounds jsonb,   -- [{round, dances:[{dance, marks}], sum, place, advanced}]
  add column if not exists judges jsonb,   -- [{letter, name, city}]
  add column if not exists source text not null default 'manual';
alter table public.competition_results drop constraint if exists competition_results_source_check;
alter table public.competition_results
  add constraint competition_results_source_check check (source in ('manual', 'auto'));

-- 3. Following a couple live on competition day -----------------------------------------------------
create table if not exists public.ksis_live_watches (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  user_couple_id uuid not null references public.user_couples(id) on delete cascade,
  event_name     text not null,
  category_name  text not null,          -- e.g. "Dospelí D ŠTT"
  event_date     date not null,
  sutaz_id       integer,                -- known once KSIS publishes the competition page
  status         text not null default 'scheduled'
                 check (status in ('scheduled', 'live', 'finished', 'stopped')),
  last_round     text,
  last_state     jsonb,                  -- what the user was last told, so every change is announced once
  updated_at     timestamptz not null default now(),
  unique (user_couple_id, event_date, category_name)
);
create index if not exists ksis_live_watches_day_idx on public.ksis_live_watches (event_date, status);
alter table public.ksis_live_watches enable row level security;
drop policy if exists ksis_live_watches_select_own on public.ksis_live_watches;
create policy ksis_live_watches_select_own on public.ksis_live_watches
  for select to authenticated using (user_id = (select auth.uid()));
-- No write policies: the server creates watches; the user stops one through the Edge Function.

-- 4. Notifications inbox (in the app now; lock-screen push later reads the same rows) --------------
create table if not exists public.user_notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  kind       text not null check (kind in ('ksis_round', 'ksis_result', 'ksis_class')),
  title      text not null,
  body       text not null,
  payload    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index if not exists user_notifications_user_idx on public.user_notifications (user_id, created_at desc);
alter table public.user_notifications enable row level security;
drop policy if exists user_notifications_select_own on public.user_notifications;
create policy user_notifications_select_own on public.user_notifications
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists user_notifications_mark_read on public.user_notifications;
create policy user_notifications_mark_read on public.user_notifications
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
-- Users may only set read_at, nothing else.
revoke update on public.user_notifications from authenticated;
grant update (read_at) on public.user_notifications to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'user_notifications') then
      alter publication supabase_realtime add table public.user_notifications;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'ksis_live_watches') then
      alter publication supabase_realtime add table public.ksis_live_watches;
    end if;
  end if;
end $$;

-- 5. Shared cache of KSIS pages: one competition is read once for everyone ------------------------
create table if not exists public.ksis_page_cache (
  url        text primary key,
  body       text not null,
  fetched_at timestamptz not null default now()
);
alter table public.ksis_page_cache enable row level security;   -- no policies: service role only

commit;

-- 6. Schedules (pg_cron + pg_net) protected by a random secret that only the database knows ------
create extension if not exists pg_cron;
create extension if not exists pg_net;

select vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'ksis_cron_secret',
                           'Shared secret for KSIS cron calls to the ksis-sync Edge Function')
 where not exists (select 1 from vault.secrets where name = 'ksis_cron_secret');

create or replace function public.ksis_cron_secret_ok(p_secret text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from vault.decrypted_secrets
                  where name = 'ksis_cron_secret' and decrypted_secret = p_secret);
$$;
revoke execute on function public.ksis_cron_secret_ok(text) from public, anon, authenticated;
grant execute on function public.ksis_cron_secret_ok(text) to service_role;

create or replace function public.ksis_cron_call(p_action text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform net.http_post(
    url := 'https://iukblwlttvrcdclmlyxu.supabase.co/functions/v1/ksis-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Cron-Secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ksis_cron_secret')
    ),
    body := jsonb_build_object('action', p_action)
  );
end $$;
revoke execute on function public.ksis_cron_call(text) from public, anon, authenticated;

-- Every morning: refresh linked couples and find competitions they are registered for (next 7 days).
select cron.schedule('ksis-daily', '0 5 * * *', $$select public.ksis_cron_call('cron_daily')$$);

-- Every 2 minutes, but only on a day with a followed competition: new rounds → notifications.
select cron.schedule('ksis-live', '*/2 * * * *', $$
  select public.ksis_cron_call('cron_live')
   where exists (select 1 from public.ksis_live_watches
                  where event_date = (now() at time zone 'Europe/Bratislava')::date
                    and status in ('scheduled', 'live'))
$$);

-- Every night: drop old cached pages and notifications.
select cron.schedule('ksis-cleanup', '30 3 * * *', $$
  delete from public.ksis_page_cache where fetched_at < now() - interval '30 days';
  delete from public.user_notifications where created_at < now() - interval '90 days';
$$);
