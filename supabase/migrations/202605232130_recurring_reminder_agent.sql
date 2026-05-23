alter table public.tabung_goals
add column if not exists recurring_start_date date,
add column if not exists reminder_enabled boolean not null default false,
add column if not exists reminder_day_of_week text,
add column if not exists reminder_day_of_month integer check (
  reminder_day_of_month is null or reminder_day_of_month between 1 and 31
);

alter table public.calendar_events
add column if not exists recurrence_rule text,
add column if not exists timezone text not null default 'Asia/Kuala_Lumpur';

create schema if not exists private;

create table if not exists private.google_calendar_tokens (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  access_token text not null,
  refresh_token text,
  token_expiry timestamptz,
  scope text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists private.google_oauth_states (
  state text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'google',
  redirect_uri text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_google_calendar_tokens_updated_at on private.google_calendar_tokens;
create trigger set_google_calendar_tokens_updated_at
before update on private.google_calendar_tokens
for each row execute function private.set_updated_at();

create index if not exists idx_private_google_oauth_states_user_id
on private.google_oauth_states(user_id);

create index if not exists idx_calendar_events_tabung_sync
on public.calendar_events(tabung_id, sync_status, created_at desc);
