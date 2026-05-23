create or replace function public.create_google_oauth_state(
  p_state text,
  p_user_id uuid,
  p_provider text,
  p_redirect_uri text,
  p_expires_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = public, private
as $$
begin
  insert into private.google_oauth_states (
    state,
    user_id,
    provider,
    redirect_uri,
    expires_at
  )
  values (
    p_state,
    p_user_id,
    coalesce(nullif(trim(p_provider), ''), 'google'),
    p_redirect_uri,
    p_expires_at
  )
  on conflict (state) do update
  set
    user_id = excluded.user_id,
    provider = excluded.provider,
    redirect_uri = excluded.redirect_uri,
    expires_at = excluded.expires_at,
    created_at = now();
end;
$$;

create or replace function public.get_google_oauth_state(p_state text)
returns table (
  state text,
  user_id uuid,
  provider text,
  redirect_uri text,
  expires_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public, private
as $$
  select
    s.state,
    s.user_id,
    s.provider,
    s.redirect_uri,
    s.expires_at,
    s.created_at
  from private.google_oauth_states s
  where s.state = p_state
  limit 1;
$$;

create or replace function public.delete_google_oauth_state(p_state text)
returns void
language plpgsql
security definer
set search_path = public, private
as $$
begin
  delete from private.google_oauth_states
  where state = p_state;
end;
$$;

create or replace function public.get_google_calendar_token(p_user_id uuid)
returns table (
  user_id uuid,
  access_token text,
  refresh_token text,
  token_expiry timestamptz,
  scope text
)
language sql
security definer
set search_path = public, private
as $$
  select
    t.user_id,
    t.access_token,
    t.refresh_token,
    t.token_expiry,
    t.scope
  from private.google_calendar_tokens t
  where t.user_id = p_user_id
  limit 1;
$$;

create or replace function public.upsert_google_calendar_token(
  p_user_id uuid,
  p_access_token text,
  p_refresh_token text,
  p_token_expiry timestamptz,
  p_scope text
)
returns void
language plpgsql
security definer
set search_path = public, private
as $$
begin
  insert into private.google_calendar_tokens (
    user_id,
    access_token,
    refresh_token,
    token_expiry,
    scope
  )
  values (
    p_user_id,
    p_access_token,
    p_refresh_token,
    p_token_expiry,
    p_scope
  )
  on conflict (user_id) do update
  set
    access_token = excluded.access_token,
    refresh_token = coalesce(excluded.refresh_token, private.google_calendar_tokens.refresh_token),
    token_expiry = excluded.token_expiry,
    scope = excluded.scope;
end;
$$;

grant execute on function public.create_google_oauth_state(text, uuid, text, text, timestamptz) to anon, authenticated, service_role;
grant execute on function public.get_google_oauth_state(text) to anon, authenticated, service_role;
grant execute on function public.delete_google_oauth_state(text) to anon, authenticated, service_role;
grant execute on function public.get_google_calendar_token(uuid) to anon, authenticated, service_role;
grant execute on function public.upsert_google_calendar_token(uuid, text, text, timestamptz, text) to anon, authenticated, service_role;
