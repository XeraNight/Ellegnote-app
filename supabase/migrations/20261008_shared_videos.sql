-- Videos shared with partner and coach live in Cloudflare R2 (no transfer fees), as 720p copies.
-- The original always stays in the owner's Fotky. This table is the source of truth for what exists
-- in R2: owner, size, figure. Only the media-share Edge Function (service role) writes it.
--
-- canvas_nodes.video_path now means "the shared copy" and holds 'r2:<key>' or null. Paths that only
-- work on one iPhone (Fotky links, app files) are refused, so they can never reach a partner.

begin;

-- 1. Shared copies -------------------------------------------------------------------------------
create table if not exists public.shared_videos (
  key            text primary key
                 check (key ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.mp4$'),   -- "<owner_id>/<uuid>.mp4"
  owner_id       uuid not null references auth.users(id) on delete cascade,
  canvas_node_id uuid references public.canvas_nodes(id) on delete set null,
  size_bytes     bigint not null check (size_bytes between 1 and 104857600),   -- 100 MB, like the bucket limit
  status         text not null default 'pending' check (status in ('pending', 'ready')),
  created_at     timestamptz not null default now()
);
create index if not exists shared_videos_owner_idx on public.shared_videos (owner_id);
create index if not exists shared_videos_node_idx on public.shared_videos (canvas_node_id);

alter table public.shared_videos enable row level security;
drop policy if exists shared_videos_owner_select on public.shared_videos;
create policy shared_videos_owner_select on public.shared_videos
  for select to authenticated
  using (owner_id = (select auth.uid()));
-- No insert, update or delete policies: users never write this table directly.

-- 2. The figure points only at a shared copy -----------------------------------------------------
update public.canvas_nodes set video_path = null
 where video_path is not null and video_path not like 'r2:%';   -- old per-device file names

alter table public.canvas_nodes drop constraint if exists canvas_nodes_video_path_shared_only;
alter table public.canvas_nodes add constraint canvas_nodes_video_path_shared_only
  check (video_path is null or video_path ~ '^r2:[0-9a-f-]{36}/[0-9a-f-]{36}\.mp4$');

-- 3. Owner check usable for any user (the Edge Function runs as service role, without auth.uid()) -
create or replace function public.is_owner_account(p_user uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from auth.users u
     where u.id = p_user
       and lower(u.email) = 'jakubkalina05@gmail.com'
       and u.email_confirmed_at is not null
  );
$$;
revoke execute on function public.is_owner_account(uuid) from public, anon, authenticated;
grant execute on function public.is_owner_account(uuid) to service_role;

create or replace function public.is_app_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.is_owner_account(auth.uid());
$$;

-- 4. Storage limit per plan (bytes): Free 1 GB, Plus 10 GB, Premium 50 GB ------------------------
create or replace function public.shared_video_quota_bytes(p_user uuid)
returns bigint language sql stable security definer set search_path = '' as $$
  select case
    when public.is_owner_account(p_user) then 53687091200
    else case coalesce((
           select e.tier from public.user_entitlements e
            where e.user_id = p_user and (e.expires_at is null or e.expires_at > now())
         ), 'free')
      when 'premium' then 53687091200
      when 'plus'    then 10737418240
      else                 1073741824
    end
  end;
$$;
revoke execute on function public.shared_video_quota_bytes(uuid) from public, anon, authenticated;
grant execute on function public.shared_video_quota_bytes(uuid) to service_role;

-- 5. Who may watch: the owner, an accepted partner (either side), or the owner's coach ------------
-- Same rule as the old storage policy on encore-media.
create or replace function public.can_view_shared_video(p_key text, p_viewer uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.shared_videos v
     where v.key = p_key
       and v.status = 'ready'
       and (
         v.owner_id = p_viewer
         or exists (
           select 1 from public.connections c
            where c.status = 'accepted'
              and (
                (c.relationship_type = 'partner'
                  and ((c.user_a_id = p_viewer and c.user_b_id = v.owner_id)
                    or (c.user_b_id = p_viewer and c.user_a_id = v.owner_id)))
                or (c.relationship_type = 'coach_student'
                  and c.user_a_id = v.owner_id and c.user_b_id = p_viewer)
              )
         )
       )
  );
$$;
revoke execute on function public.can_view_shared_video(text, uuid) from public, anon, authenticated;
grant execute on function public.can_view_shared_video(text, uuid) to service_role;

commit;
