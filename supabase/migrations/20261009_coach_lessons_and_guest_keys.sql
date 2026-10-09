-- Coach tools and guest coach keys (docs/V1_PAYWALL_FEATURES_PLAN.md, features 4 and 6).
--
-- 1. "Čo sme robili naposledy" (Premium): a coach writes a short lesson summary per student; only the coach
--    sees it. Trainer notes on figures are already protected by guard_canvas_coach_notes (20261007): the
--    student can neither change nor clear them.
-- 2. Guest coach key: the dancer lends one routine to a guest coach (seminar) through a random key.
--    Free: one active key, at most 7 days. Plus/Premium: any number, at most 30 days. The guest sees figure
--    names and rhythm only (no notes of the dancer or of other coaches) and adds own notes, which stay with
--    the dancer after the key expires. The key is random (128 bit), stored only as a SHA-256 hash, single
--    guest, revocable by the dancer, and expires by itself.

begin;

-- The plan the server enforces (the owner account counts as Premium). Same source as shared_video_quota_bytes.
create or replace function public.user_plan(p_user uuid)
returns text
language sql stable security definer set search_path = '' as $$
  select case
    when public.is_owner_account(p_user) then 'premium'
    else coalesce((
      select e.tier from public.user_entitlements e
       where e.user_id = p_user and (e.expires_at is null or e.expires_at > now())
    ), 'free')
  end;
$$;
revoke all on function public.user_plan(uuid) from public, anon, authenticated;

-- 1. Coach lessons ------------------------------------------------------------------------------------
create or replace function public.is_coach_of_student(p_student uuid)
returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.connections c
     where c.status = 'accepted' and c.relationship_type = 'coach_student'
       and c.user_a_id = p_student and c.user_b_id = auth.uid()
  );
$$;
revoke all on function public.is_coach_of_student(uuid) from public, anon;
grant execute on function public.is_coach_of_student(uuid) to authenticated;

create table if not exists public.coach_lessons (
  id          uuid primary key default gen_random_uuid(),
  coach_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  student_id  uuid not null references auth.users(id) on delete cascade,
  lesson_date date not null default current_date,
  summary     text not null check (char_length(btrim(summary)) between 1 and 2000),
  created_at  timestamptz not null default now()
);
create index if not exists coach_lessons_coach_student_idx
  on public.coach_lessons (coach_id, student_id, lesson_date desc, created_at desc);
alter table public.coach_lessons enable row level security;

drop policy if exists coach_lessons_select on public.coach_lessons;
create policy coach_lessons_select on public.coach_lessons
  for select to authenticated using (coach_id = (select auth.uid()));
drop policy if exists coach_lessons_insert on public.coach_lessons;
create policy coach_lessons_insert on public.coach_lessons
  for insert to authenticated
  with check (coach_id = (select auth.uid())
              and public.is_coach_of_student(student_id)
              and public.user_plan((select auth.uid())) = 'premium');
drop policy if exists coach_lessons_update on public.coach_lessons;
create policy coach_lessons_update on public.coach_lessons
  for update to authenticated
  using (coach_id = (select auth.uid()))
  with check (coach_id = (select auth.uid()) and public.is_coach_of_student(student_id));
drop policy if exists coach_lessons_delete on public.coach_lessons;
create policy coach_lessons_delete on public.coach_lessons
  for delete to authenticated using (coach_id = (select auth.uid()));
drop policy if exists active_account_only on public.coach_lessons;
create policy active_account_only on public.coach_lessons as restrictive
  for all to authenticated
  using ((select public.is_account_active())) with check ((select public.is_account_active()));

-- 2. Guest coach keys ---------------------------------------------------------------------------------
create table if not exists public.guest_coach_keys (
  id          uuid primary key default gen_random_uuid(),
  routine_id  uuid not null references public.routines(id) on delete cascade,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  token_hash  text not null unique,                 -- SHA-256 of the key; the key itself is never stored
  expires_at  timestamptz not null,
  created_at  timestamptz not null default now(),
  revoked_at  timestamptz,
  guest_id    uuid references auth.users(id) on delete set null,
  guest_name  text,
  redeemed_at timestamptz
);
create index if not exists guest_coach_keys_owner_idx on public.guest_coach_keys (owner_id, created_at desc);
create index if not exists guest_coach_keys_guest_idx on public.guest_coach_keys (guest_id) where guest_id is not null;
alter table public.guest_coach_keys enable row level security;

-- Read: the dancer who made the key and the guest who used it. Writes only through the functions below.
drop policy if exists guest_coach_keys_select on public.guest_coach_keys;
create policy guest_coach_keys_select on public.guest_coach_keys
  for select to authenticated
  using (owner_id = (select auth.uid()) or guest_id = (select auth.uid()));
drop policy if exists active_account_only on public.guest_coach_keys;
create policy active_account_only on public.guest_coach_keys as restrictive
  for all to authenticated
  using ((select public.is_account_active())) with check ((select public.is_account_active()));

create table if not exists public.guest_coach_notes (
  id          uuid primary key default gen_random_uuid(),
  key_id      uuid not null references public.guest_coach_keys(id) on delete cascade,
  routine_id  uuid not null references public.routines(id) on delete cascade,
  node_id     uuid not null references public.canvas_nodes(id) on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  body        text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at  timestamptz not null default now()
);
create index if not exists guest_coach_notes_node_idx on public.guest_coach_notes (node_id, created_at);
create index if not exists guest_coach_notes_routine_idx on public.guest_coach_notes (routine_id);
alter table public.guest_coach_notes enable row level security;

-- Write: the guest, with a valid key for this routine, on a figure of this routine.
drop policy if exists guest_coach_notes_insert on public.guest_coach_notes;
create policy guest_coach_notes_insert on public.guest_coach_notes
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and exists (select 1 from public.guest_coach_keys k
                 where k.id = key_id and k.guest_id = (select auth.uid()) and k.routine_id = guest_coach_notes.routine_id
                   and k.revoked_at is null and k.expires_at > now())
    and exists (select 1 from public.canvas_nodes n where n.id = node_id and n.routine_id = guest_coach_notes.routine_id)
  );
-- Read and delete: the guest who wrote it and the dancer who owns the routine.
drop policy if exists guest_coach_notes_select on public.guest_coach_notes;
create policy guest_coach_notes_select on public.guest_coach_notes
  for select to authenticated
  using (author_id = (select auth.uid())
         or exists (select 1 from public.routines r where r.id = routine_id and r.user_id = (select auth.uid())));
drop policy if exists guest_coach_notes_delete on public.guest_coach_notes;
create policy guest_coach_notes_delete on public.guest_coach_notes
  for delete to authenticated
  using (author_id = (select auth.uid())
         or exists (select 1 from public.routines r where r.id = routine_id and r.user_id = (select auth.uid())));
drop policy if exists active_account_only on public.guest_coach_notes;
create policy active_account_only on public.guest_coach_notes as restrictive
  for all to authenticated
  using ((select public.is_account_active())) with check ((select public.is_account_active()));

-- Make a key for one of my routines. Returns the key once; only its hash is stored.
create or replace function public.create_guest_coach_key(p_routine_id uuid, p_days integer)
returns table (key_id uuid, token text, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_plan text;
  v_token text;
  v_id uuid;
  v_expires timestamptz;
begin
  if v_uid is null or not public.is_account_active() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if not exists (select 1 from public.routines r where r.id = p_routine_id and r.user_id = v_uid) then
    raise exception 'not_owner' using errcode = '42501';
  end if;
  v_plan := public.user_plan(v_uid);
  if p_days is null or p_days < 1 or p_days > (case when v_plan = 'free' then 7 else 30 end) then
    raise exception 'days_out_of_range' using errcode = '22023';
  end if;
  if v_plan = 'free' and exists (
    select 1 from public.guest_coach_keys k
     where k.owner_id = v_uid and k.revoked_at is null and k.expires_at > now()
  ) then
    raise exception 'free_limit' using errcode = 'P0001';
  end if;

  v_token := encode(extensions.gen_random_bytes(16), 'hex');
  v_expires := now() + make_interval(days => p_days);
  insert into public.guest_coach_keys (routine_id, owner_id, token_hash, expires_at)
  values (p_routine_id, v_uid, encode(extensions.digest(v_token, 'sha256'), 'hex'), v_expires)
  returning id into v_id;
  return query select v_id, v_token, v_expires;
end $$;
revoke all on function public.create_guest_coach_key(uuid, integer) from public, anon;
grant execute on function public.create_guest_coach_key(uuid, integer) to authenticated;

-- Use a key: the first guest who uses it keeps it until it expires or is revoked.
create or replace function public.redeem_guest_coach_key(p_token text)
returns table (key_id uuid, routine_id uuid, routine_name text, dance_name text, owner_name text, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_key public.guest_coach_keys%rowtype;
begin
  if v_uid is null or not public.is_account_active() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_token is null or p_token !~ '^[0-9a-f]{32}$' then
    raise exception 'invalid_key' using errcode = '22023';
  end if;
  select * into v_key from public.guest_coach_keys k
   where k.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
   for update;
  if not found or v_key.revoked_at is not null or v_key.expires_at <= now() then
    raise exception 'invalid_key' using errcode = '22023';
  end if;
  if v_key.owner_id = v_uid then
    raise exception 'own_key' using errcode = '22023';
  end if;
  if v_key.guest_id is not null and v_key.guest_id <> v_uid then
    raise exception 'key_used' using errcode = '22023';
  end if;

  update public.guest_coach_keys k
     set guest_id = v_uid,
         guest_name = (select p.name from public.profiles p where p.id = v_uid),
         redeemed_at = coalesce(k.redeemed_at, now())
   where k.id = v_key.id;

  return query
    select v_key.id, r.id, r.name, r.dance_name, coalesce(p.name, ''), v_key.expires_at
      from public.routines r left join public.profiles p on p.id = r.user_id
     where r.id = v_key.routine_id;
end $$;
revoke all on function public.redeem_guest_coach_key(text) from public, anon;
grant execute on function public.redeem_guest_coach_key(text) to authenticated;

-- End a key: the dancer revokes it, or the guest leaves.
create or replace function public.revoke_guest_coach_key(p_key_id uuid)
returns void
language sql security definer set search_path = '' as $$
  update public.guest_coach_keys k
     set revoked_at = now()
   where k.id = p_key_id and k.revoked_at is null
     and (k.owner_id = auth.uid() or k.guest_id = auth.uid());
$$;
revoke all on function public.revoke_guest_coach_key(uuid) from public, anon;
grant execute on function public.revoke_guest_coach_key(uuid) to authenticated;

-- What the guest sees: the routine's figures, names and rhythm only.
create or replace function public.guest_routine_figures(p_routine_id uuid)
returns table (node_id uuid, figure_name text, rhythm text, order_index integer)
language sql stable security definer set search_path = '' as $$
  select n.id, n.figure_name, n.rhythm, n.order_index
    from public.canvas_nodes n
   where n.routine_id = p_routine_id
     and exists (select 1 from public.guest_coach_keys k
                  where k.routine_id = p_routine_id and k.guest_id = auth.uid()
                    and k.revoked_at is null and k.expires_at > now())
   order by n.order_index;
$$;
revoke all on function public.guest_routine_figures(uuid) from public, anon;
grant execute on function public.guest_routine_figures(uuid) to authenticated;

-- "Stiahnuť moje dáta": the same export as 20261008_export_shared_videos.sql plus the new tables.
create or replace function public.export_my_data()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'exported_at', now(),

    'account', (
      select jsonb_build_object(
        'id', u.id,
        'email', u.email,
        'created_at', u.created_at,
        'email_confirmed_at', u.email_confirmed_at,
        'last_sign_in_at', u.last_sign_in_at,
        'sign_in_methods', u.raw_app_meta_data->'providers'
      )
      from auth.users u
      where u.id = v_uid
    ),

    'profile', (
      select to_jsonb(p) - 'invite_code'
      from public.profiles p
      where p.id = v_uid
    ),

    'routines', coalesce((
      select jsonb_agg(
        to_jsonb(r) || jsonb_build_object('figures', coalesce((
          select jsonb_agg(to_jsonb(n) - 'coach_notes_by' order by n.order_index)
          from public.canvas_nodes n
          where n.routine_id = r.id
        ), '[]'::jsonb))
        order by r.updated_at desc)
      from public.routines r
      where r.user_id = v_uid
    ), '[]'::jsonb),

    'coach_notes_written', coalesce((
      select jsonb_agg(jsonb_build_object('figure_id', n.id, 'note', n.coach_notes, 'written_at', n.coach_notes_at)
                       order by n.coach_notes_at)
      from public.canvas_nodes n
      where n.coach_notes_by = v_uid
    ), '[]'::jsonb),

    'figure_library', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.created_at)
      from public.figure_library_items f
      where f.user_id = v_uid
    ), '[]'::jsonb),

    'connections', coalesce((
      select jsonb_agg(jsonb_build_object(
        'relationship', c.relationship_type,
        'status', c.status,
        'other_person', other.full_name,
        'requested_by_me', c.initiated_by = v_uid,
        'created_at', c.created_at,
        'updated_at', c.updated_at
      ) order by c.created_at)
      from public.connections c
      left join public.profiles other
        on other.id = case when c.user_a_id = v_uid then c.user_b_id else c.user_a_id end
      where v_uid in (c.user_a_id, c.user_b_id)
    ), '[]'::jsonb),

    'friends', coalesce((
      select jsonb_agg(jsonb_build_object(
        'status', fr.status,
        'other_person', other.full_name,
        'requested_by_me', fr.user_id = v_uid,
        'created_at', fr.created_at,
        'updated_at', fr.updated_at
      ) order by fr.created_at)
      from public.friends fr
      left join public.profiles other
        on other.id = case when fr.user_id = v_uid then fr.friend_id else fr.user_id end
      where v_uid in (fr.user_id, fr.friend_id)
    ), '[]'::jsonb),

    'couples', coalesce((
      select jsonb_agg(to_jsonb(uc) order by uc.created_at)
      from public.user_couples uc
      where uc.user_id = v_uid
    ), '[]'::jsonb),

    'competition_results', coalesce((
      select jsonb_agg(to_jsonb(cr) order by cr.date desc)
      from public.competition_results cr
      where cr.user_id = v_uid
    ), '[]'::jsonb),

    'membership', (
      select to_jsonb(e) - 'granted_by'
      from public.user_entitlements e
      where e.user_id = v_uid
    ),

    'invite_links', coalesce((
      select jsonb_agg(jsonb_build_object('created_at', t.created_at, 'expires_at', t.expires_at, 'revoked_at', t.revoked_at)
                       order by t.created_at)
      from public.invite_tokens t
      where t.user_id = v_uid
    ), '[]'::jsonb),

    'emails_sent', coalesce((
      select jsonb_agg(jsonb_build_object('kind', l.kind, 'sent_at', l.created_at) order by l.created_at)
      from public.email_send_log l
      where l.user_id = v_uid
    ), '[]'::jsonb),

    'shared_videos', coalesce((
      select jsonb_agg(jsonb_build_object(
        'figure_id', v.canvas_node_id,
        'size_bytes', v.size_bytes,
        'status', v.status,
        'shared_at', v.created_at
      ) order by v.created_at)
      from public.shared_videos v
      where v.owner_id = v_uid
    ), '[]'::jsonb),

    'coach_lessons_written', coalesce((
      select jsonb_agg(jsonb_build_object(
        'student', coalesce(other.name, other.full_name),
        'lesson_date', l.lesson_date,
        'summary', l.summary,
        'created_at', l.created_at
      ) order by l.lesson_date, l.created_at)
      from public.coach_lessons l
      left join public.profiles other on other.id = l.student_id
      where l.coach_id = v_uid
    ), '[]'::jsonb),

    'guest_coach_keys_made', coalesce((
      select jsonb_agg(jsonb_build_object(
        'routine_id', k.routine_id,
        'created_at', k.created_at,
        'expires_at', k.expires_at,
        'revoked_at', k.revoked_at,
        'used_by', k.guest_name,
        'used_at', k.redeemed_at
      ) order by k.created_at)
      from public.guest_coach_keys k
      where k.owner_id = v_uid
    ), '[]'::jsonb),

    'guest_coach_keys_used', coalesce((
      select jsonb_agg(jsonb_build_object(
        'routine', r.name,
        'used_at', k.redeemed_at,
        'expires_at', k.expires_at,
        'revoked_at', k.revoked_at
      ) order by k.redeemed_at)
      from public.guest_coach_keys k
      left join public.routines r on r.id = k.routine_id
      where k.guest_id = v_uid
    ), '[]'::jsonb),

    'guest_notes_written', coalesce((
      select jsonb_agg(jsonb_build_object('figure_id', g.node_id, 'note', g.body, 'written_at', g.created_at)
                       order by g.created_at)
      from public.guest_coach_notes g
      where g.author_id = v_uid
    ), '[]'::jsonb),

    'guest_notes_on_my_routines', coalesce((
      select jsonb_agg(jsonb_build_object('figure_id', g.node_id, 'note', g.body, 'by', k.guest_name, 'written_at', g.created_at)
                       order by g.created_at)
      from public.guest_coach_notes g
      join public.routines r on r.id = g.routine_id and r.user_id = v_uid
      left join public.guest_coach_keys k on k.id = g.key_id
    ), '[]'::jsonb),

    'uploaded_files', coalesce((
      select jsonb_agg(jsonb_build_object(
        'path', o.name,
        'size_bytes', (o.metadata->>'size')::bigint,
        'uploaded_at', o.created_at
      ) order by o.created_at)
      from storage.objects o
      where o.bucket_id = 'encore-media'
        and (storage.foldername(o.name))[1] = v_uid::text
    ), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.export_my_data() from public, anon;
grant execute on function public.export_my_data() to authenticated;

commit;
