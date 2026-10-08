-- Plans are Free, Plus and Premium, always personal. The old top plan "studio" becomes "premium".
-- The app reads both values (SubscriptionTier.init(serverValue:)), so it works before and after this runs.
-- Both functions keep their bodies and grants; only the tier names change.

begin;

alter table public.user_entitlements drop constraint if exists user_entitlements_tier_check;
update public.user_entitlements set tier = 'premium', updated_at = now() where tier = 'studio';
alter table public.user_entitlements
  add constraint user_entitlements_tier_check check (tier in ('free', 'plus', 'premium'));

create or replace function public.admin_grant_entitlement_by_email(
  p_email text,
  p_tier text,
  p_duration_months integer default null,
  p_note text default 'VIP Darovanie od majiteľa'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_target uuid;
  v_exp timestamptz := null;
begin
  if not public.is_app_owner() then
    return jsonb_build_object('success', false, 'error_code', 'FORBIDDEN',
                              'message', 'Nemáš oprávnenie majiteľa aplikácie.');
  end if;

  if lower(p_tier) not in ('free', 'plus', 'premium') then
    return jsonb_build_object('success', false, 'error_code', 'BAD_TIER',
                              'message', 'Neplatná úroveň predplatného.');
  end if;

  select id into v_target
  from auth.users
  where lower(email) = lower(trim(p_email))
  limit 1;

  if v_target is null then
    return jsonb_build_object(
      'success', false,
      'error_code', 'USER_NOT_FOUND',
      'message', 'Používateľ ' || p_email || ' sa ešte nezaregistroval v Encore.'
    );
  end if;

  if p_duration_months is not null and p_duration_months > 0 then
    v_exp := now() + (p_duration_months || ' months')::interval;
  end if;

  insert into public.user_entitlements (user_id, tier, source, expires_at, granted_by, notes, updated_at)
  values (v_target, lower(p_tier), 'owner_grant', v_exp, auth.uid(), p_note, now())
  on conflict (user_id) do update set
    tier = excluded.tier,
    source = 'owner_grant',
    expires_at = excluded.expires_at,
    granted_by = auth.uid(),
    notes = excluded.notes,
    updated_at = now();

  return jsonb_build_object(
    'success', true,
    'message', 'Plán ' || upper(p_tier) || ' bol úspešne udelený pre ' || p_email || '!'
  );
end $function$;

create or replace function public.record_app_store_transaction(
  p_tier text,
  p_product_id text,
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    return jsonb_build_object('success', false, 'error_code', 'UNAUTHORIZED');
  end if;

  if lower(p_tier) not in ('free', 'plus', 'premium') then
    return jsonb_build_object('success', false, 'error_code', 'BAD_TIER');
  end if;

  insert into public.user_entitlements (user_id, tier, source, expires_at, notes, updated_at)
  values (v_user, lower(p_tier), 'storekit', p_expires_at, 'StoreKit 2: ' || p_product_id, now())
  on conflict (user_id) do update set
    tier = case
      when user_entitlements.source = 'owner_grant' and user_entitlements.tier = 'premium' then user_entitlements.tier
      else excluded.tier
    end,
    source = case
      when user_entitlements.source = 'owner_grant' and user_entitlements.tier = 'premium' then user_entitlements.source
      else 'storekit'
    end,
    expires_at = case
      when user_entitlements.source = 'owner_grant' and user_entitlements.tier = 'premium' then user_entitlements.expires_at
      else excluded.expires_at
    end,
    notes = excluded.notes,
    updated_at = now();

  return jsonb_build_object('success', true);
end $function$;

commit;
