-- App config for emergencies: force update and maintenance notice (RemoteConfigManager).
-- Replaces the dead Vercel endpoint /api/app-config. One row; everyone may read it, only the
-- dashboard / service role can change it (no write policies).
-- Usage: Table Editor → app_config → set min_version (e.g. '1.0.1') or maintenance_mode = true.

create table if not exists public.app_config (
  id                  boolean primary key default true check (id),   -- exactly one row
  min_version         text,                                          -- older app versions must update
  maintenance_mode    boolean not null default false,
  maintenance_message text,
  app_store_url       text,
  updated_at          timestamptz not null default now()
);

alter table public.app_config enable row level security;

drop policy if exists app_config_read on public.app_config;
create policy app_config_read on public.app_config
  for select to anon, authenticated using (true);

insert into public.app_config (id) values (true) on conflict (id) do nothing;
