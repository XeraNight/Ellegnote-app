-- P0: a user could write an *accepted* coach_student / partner connection to someone else's account
-- straight from the client (policy "connections_user_access" is FOR ALL with no WITH CHECK and there is
-- no trigger). The attacker only needs the victim's user id (search_dancers returns it) to read the
-- victim's routines and videos and to change their routines.
--
-- Rules enforced for direct client calls (role "authenticated"). SECURITY DEFINER RPCs such as
-- respond_to_friend_invite run as the function owner and are not affected.
--   INSERT : only as 'pending', initiated_by = me, and I am one of the two people.
--   UPDATE : people, type and the pair never change.
--            pending  -> accepted / rejected : only by the person who did NOT initiate it.
--            pending / accepted -> revoked   : either person.
--            rejected / revoked -> pending   : re-request by whoever sends it now (initiated_by = me).
--   Anything else is refused.

create or replace function public.guard_connection_changes()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  -- Service role, SQL editor and SECURITY DEFINER functions are not restricted here.
  if v_me is null or current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status <> 'pending'
       or new.initiated_by is distinct from v_me
       or v_me not in (new.user_a_id, new.user_b_id)
       or new.user_a_id = new.user_b_id then
      raise exception 'Invalid connection request' using errcode = '42501';
    end if;
    return new;
  end if;

  -- UPDATE (this also covers upsert on conflict)
  if new.user_a_id is distinct from old.user_a_id
     or new.user_b_id is distinct from old.user_b_id
     or new.relationship_type is distinct from old.relationship_type then
    raise exception 'Connection parties cannot change' using errcode = '42501';
  end if;

  if new.status = old.status then
    new.initiated_by := old.initiated_by;
    return new;
  end if;

  if new.status in ('accepted', 'rejected') then
    if old.status <> 'pending' or old.initiated_by = v_me then
      raise exception 'Only the invited person can answer a pending request' using errcode = '42501';
    end if;
    new.initiated_by := old.initiated_by;
  elsif new.status = 'revoked' then
    if old.status not in ('pending', 'accepted') then
      raise exception 'Nothing to revoke' using errcode = '42501';
    end if;
    new.initiated_by := old.initiated_by;
  elsif new.status = 'pending' then
    if old.status not in ('rejected', 'revoked') or new.initiated_by is distinct from v_me then
      raise exception 'Invalid connection request' using errcode = '42501';
    end if;
  else
    raise exception 'Invalid connection status' using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke all on function public.guard_connection_changes() from public, anon;

drop trigger if exists connections_guard_changes on public.connections;
create trigger connections_guard_changes
  before insert or update on public.connections
  for each row execute function public.guard_connection_changes();

-- Existing rows are left as they are. Review once by hand:
--   select * from public.connections where status = 'accepted' and initiated_by in (user_a_id, user_b_id);
