-- ==============================================================================
-- Encore — User Account Self-Deletion Function (Apple Guideline 5.1.1(v))
-- Run this in Supabase Dashboard > SQL Editor.
-- ==============================================================================

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    current_uid uuid;
begin
    -- Get caller's authenticated user ID
    current_uid := auth.uid();
    
    if current_uid is null then
        raise exception 'Not authenticated';
    end if;

    -- Delete user profile (cascades or cleans up user data)
    delete from public.profiles where id = current_uid;

    -- Delete user account from Supabase auth.users
    delete from auth.users where id = current_uid;
end;
$$;

-- Grant execution permission only to authenticated users
revoke execute on function public.delete_user_account() from public;
revoke execute on function public.delete_user_account() from anon;
grant execute on function public.delete_user_account() to authenticated;
