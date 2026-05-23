-- Fix ambiguous family_id references in onboarding RPCs.

create or replace function public.register_parent_account(
  p_full_name text,
  p_email text,
  p_family_name text
)
returns table (
  family_id uuid,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_family_id uuid;
  v_invite_code text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id, full_name, role, email)
  values (v_user_id, p_full_name, 'parent', p_email)
  on conflict (id) do update
    set full_name = excluded.full_name,
        role = excluded.role,
        email = excluded.email,
        updated_at = now();

  insert into public.families as fam (family_name, created_by)
  values (p_family_name, v_user_id)
  returning fam.id, fam.invite_code into v_family_id, v_invite_code;

  insert into public.family_members (family_id, user_id)
  values (v_family_id, v_user_id)
  on conflict on constraint family_members_family_id_user_id_key do nothing;

  return query
  select v_family_id as family_id, v_invite_code as invite_code;
end;
$$;

create or replace function public.register_child_account(
  p_full_name text,
  p_email text,
  p_invite_code text
)
returns table (
  family_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_family_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select f.id into v_family_id
  from public.families f
  where upper(f.invite_code) = upper(trim(p_invite_code))
  limit 1;

  if v_family_id is null then
    raise exception 'Invalid family code';
  end if;

  insert into public.profiles (id, full_name, role, email)
  values (v_user_id, p_full_name, 'child', p_email)
  on conflict (id) do update
    set full_name = excluded.full_name,
        role = excluded.role,
        email = excluded.email,
        updated_at = now();

  insert into public.family_members (family_id, user_id)
  values (v_family_id, v_user_id)
  on conflict on constraint family_members_family_id_user_id_key do nothing;

  return query
  select v_family_id as family_id;
end;
$$;
