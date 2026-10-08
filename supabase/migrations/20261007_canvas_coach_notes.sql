-- Trainer notes on a figure: separate fields, written only by the student's coach.
-- The student (and partner) see them read-only; the coach can change nothing else on the node.

alter table public.canvas_nodes
  add column if not exists coach_notes text,
  add column if not exists coach_notes_by uuid references auth.users(id) on delete set null,
  add column if not exists coach_notes_at timestamptz;

create or replace function public.is_coach_of_routine(p_routine_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from routines r
    join connections c
      on c.status = 'accepted'
     and c.relationship_type = 'coach_student'
     and c.user_a_id = r.user_id
     and c.user_b_id = auth.uid()
    where r.id = p_routine_id
  );
$$;

revoke all on function public.is_coach_of_routine(uuid) from public, anon;
grant execute on function public.is_coach_of_routine(uuid) to authenticated;

create or replace function public.guard_canvas_coach_notes()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_is_coach boolean;
  v_is_owner boolean;
begin
  -- Service role / SQL editor: no restriction.
  if auth.uid() is null then
    return new;
  end if;

  v_is_owner := exists (select 1 from routines r where r.id = new.routine_id and r.user_id = auth.uid());
  v_is_coach := not v_is_owner and public.is_coach_of_routine(new.routine_id);

  if v_is_coach then
    -- Coach: only the coach_notes field may change; author and time are set by the server.
    if (new.x, new.y, new.figure_name, new.rhythm, new.notes, new.video_path,
        new.order_index, new.transition_notes, new.routine_id)
       is distinct from
       (old.x, old.y, old.figure_name, old.rhythm, old.notes, old.video_path,
        old.order_index, old.transition_notes, old.routine_id) then
      raise exception 'Coach may only edit coach notes' using errcode = '42501';
    end if;
    if new.coach_notes is distinct from old.coach_notes then
      new.coach_notes_by := auth.uid();
      new.coach_notes_at := now();
    end if;
  else
    -- Student / partner: coach notes are read-only.
    new.coach_notes := old.coach_notes;
    new.coach_notes_by := old.coach_notes_by;
    new.coach_notes_at := old.coach_notes_at;
  end if;

  return new;
end;
$$;

drop trigger if exists canvas_guard_coach_notes on public.canvas_nodes;
create trigger canvas_guard_coach_notes
  before update on public.canvas_nodes
  for each row execute function public.guard_canvas_coach_notes();

-- Inserts: nobody can plant coach notes on a new node.
create or replace function public.clear_canvas_coach_notes_on_insert()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null then
    new.coach_notes := null;
    new.coach_notes_by := null;
    new.coach_notes_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists canvas_clear_coach_notes_insert on public.canvas_nodes;
create trigger canvas_clear_coach_notes_insert
  before insert on public.canvas_nodes
  for each row execute function public.clear_canvas_coach_notes_on_insert();
