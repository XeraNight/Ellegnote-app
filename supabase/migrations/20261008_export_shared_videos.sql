-- "Stiahnuť moje dáta" also lists the videos shared with partner and coach (Cloudflare R2 copies):
-- which figure, size, state and when. Same function as 20261007_export_my_data.sql plus that section.

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
