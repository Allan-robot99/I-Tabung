-- ============================================================
-- I-Tabung Supabase PostgreSQL Schema
-- Application: Malaysian parent-child savings app
-- AI Agents:
-- 1. Goal Planner Agent
-- 2. Spending Habit Coach Agent
-- 3. Recurring Goal Reminder Agent
--
-- Designed for:
-- - Supabase Auth
-- - Supabase PostgreSQL
-- - Flutter frontend
-- - Supabase Edge Functions
-- - Gemini API
-- - Optional Google Calendar API integration
-- ============================================================

create extension if not exists "pgcrypto";
create schema if not exists private;

-- ============================================================
-- 1. DROP OLD DEVELOPMENT OBJECTS
-- Comment this section if you already have production data.
-- ============================================================

drop view if exists public.tabung_dashboard_view cascade;

drop table if exists public.ai_logs cascade;
drop table if exists private.google_oauth_states cascade;
drop table if exists private.google_calendar_tokens cascade;
drop table if exists public.calendar_events cascade;
drop table if exists public.calendar_connections cascade;
drop table if exists public.notifications cascade;
drop table if exists public.recurring_goal_logs cascade;
drop table if exists public.payment_transactions cascade;
drop table if exists public.savings_entries cascade;
drop table if exists public.milestones cascade;
drop table if exists public.tabung_requests cascade;
drop table if exists public.tabung_goals cascade;
drop table if exists public.family_members cascade;
drop table if exists public.families cascade;
drop table if exists public.profiles cascade;

drop function if exists public.set_updated_at() cascade;
drop function if exists public.generate_invite_code() cascade;
drop function if exists public.is_family_member(uuid) cascade;
drop function if exists public.is_family_parent(uuid) cascade;
drop function if exists public.can_access_tabung(uuid) cascade;
drop function if exists public.is_tabung_child(uuid) cascade;
drop function if exists public.refresh_tabung_current_amount() cascade;
drop function if exists public.unlock_reached_milestones() cascade;
drop function if exists public.create_google_oauth_state(text, uuid, text, text, timestamptz) cascade;
drop function if exists public.get_google_oauth_state(text) cascade;
drop function if exists public.delete_google_oauth_state(text) cascade;
drop function if exists public.get_google_calendar_token(uuid) cascade;
drop function if exists public.upsert_google_calendar_token(uuid, text, text, timestamptz, text) cascade;

drop type if exists public.user_role cascade;
drop type if exists public.tabung_type cascade;
drop type if exists public.tabung_status cascade;
drop type if exists public.request_status cascade;
drop type if exists public.recurring_period cascade;
drop type if exists public.milestone_status cascade;
drop type if exists public.payment_status cascade;
drop type if exists public.recurring_log_status cascade;
drop type if exists public.notification_type cascade;
drop type if exists public.calendar_event_type cascade;
drop type if exists public.calendar_sync_status cascade;
drop type if exists public.ai_agent_type cascade;

-- ============================================================
-- 2. ENUM TYPES
-- ============================================================

create type public.user_role as enum (
  'parent',
  'child'
);

create type public.tabung_type as enum (
  'education',
  'gadget',
  'emergency',
  'travel',
  'custom',
  'electronic device',
  'food',
  'growth fund',
  'sport and art'
);

create type public.tabung_status as enum (
  'pending',
  'active',
  'rejected',
  'completed',
  'paused'
);

create type public.request_status as enum (
  'pending',
  'approved',
  'rejected',
  'cancelled'
);

create type public.recurring_period as enum (
  'daily',
  'weekly',
  'monthly'
);

create type public.milestone_status as enum (
  'locked',
  'unlocked',
  'claimed'
);

create type public.payment_status as enum (
  'pending_review',
  'confirmed',
  'cancelled'
);

create type public.recurring_log_status as enum (
  'met',
  'missed',
  'partial'
);

create type public.notification_type as enum (
  'tabung_request',
  'tabung_approved',
  'tabung_rejected',
  'payment_warning',
  'recurring_reminder',
  'milestone',
  'calendar',
  'system'
);

create type public.calendar_event_type as enum (
  'deadline',
  'recurring_target',
  'catch_up'
);

create type public.calendar_sync_status as enum (
  'pending',
  'synced',
  'failed',
  'not_connected'
);

create type public.ai_agent_type as enum (
  'goal_planner',
  'spending_habit_coach',
  'recurring_goal_reminder'
);

-- ============================================================
-- 3. BASIC UTILITY FUNCTIONS
-- These do not depend on application tables.
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.generate_invite_code()
returns text
language sql
as $$
  select upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
$$;

-- ============================================================
-- 4. CORE TABLES
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 profiles
-- Linked to Supabase auth.users.
-- Do not store password here. Supabase Auth handles passwords.
-- ------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null,
  email text,
  preferred_language text default 'en' check (preferred_language in ('en', 'ms')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 4.2 families
-- A parent creates a family group. Children join through invite code.
-- ------------------------------------------------------------

create table public.families (
  id uuid primary key default gen_random_uuid(),
  family_name text not null,
  invite_code text not null unique default public.generate_invite_code(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_families_updated_at
before update on public.families
for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 4.3 family_members
-- Links parents and children to family groups.
-- ------------------------------------------------------------

create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (family_id, user_id)
);

-- ------------------------------------------------------------
-- 4.4 tabung_goals
-- Main savings goal table.
--
-- Goal Planner Agent output should be stored here:
-- - recurring_amount
-- - recurring_period
-- - milestone suggestions are inserted into milestones table
-- - period_suggestion_months
-- - contribution ratio fields
-- - ai_plan as full JSON output
-- ------------------------------------------------------------

create table public.tabung_goals (
  id uuid primary key default gen_random_uuid(),

  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.profiles(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,

  tabung_type public.tabung_type not null default 'custom',
  tabung_name text not null,
  description text,
  reason text,

  goal_amount numeric(12,2) not null check (goal_amount > 0),
  current_amount numeric(12,2) not null default 0 check (current_amount >= 0),
  initial_savings numeric(12,2) not null default 0 check (initial_savings >= 0),

  desired_deadline date,
  deadline date,
  preferred_period_months integer check (preferred_period_months is null or preferred_period_months > 0),
  status public.tabung_status not null default 'pending',

  child_monthly_allowance numeric(12,2) default 0 check (child_monthly_allowance >= 0),
  child_possible_monthly_saving numeric(12,2) default 0 check (child_possible_monthly_saving >= 0),
  parent_support_needed boolean not null default false,
  parent_preferred_contribution numeric(12,2) check (parent_preferred_contribution is null or parent_preferred_contribution >= 0),

  -- Goal Planner Agent: recurring target suggestion
  recurring_amount numeric(12,2) check (recurring_amount is null or recurring_amount > 0),
  recurring_period public.recurring_period,
  recurring_start_date date,
  recurring_reason text,
  reminder_day text,
  reminder_enabled boolean not null default false,
  reminder_time time,
  reminder_day_of_week text,
  reminder_day_of_month integer check (
    reminder_day_of_month is null or reminder_day_of_month between 1 and 31
  ),
  last_checked_at timestamptz,

  -- Goal Planner Agent: contribution ratio suggestion
  child_contribution_amount numeric(12,2) default 0 check (child_contribution_amount >= 0),
  parent_contribution_amount numeric(12,2) default 0 check (parent_contribution_amount >= 0),
  child_contribution_percentage numeric(5,2) default 0 check (child_contribution_percentage >= 0 and child_contribution_percentage <= 100),
  parent_contribution_percentage numeric(5,2) default 0 check (parent_contribution_percentage >= 0 and parent_contribution_percentage <= 100),
  contribution_ratio_reason text,

  -- Goal Planner Agent: period and difficulty suggestion
  period_suggestion_months integer check (period_suggestion_months is null or period_suggestion_months > 0),
  suggested_deadline date,
  period_suggestion_reason text,
  difficulty_level text check (difficulty_level is null or difficulty_level in ('Easy', 'Medium', 'Hard')),

  -- Full AI response
  ai_plan jsonb,
  ai_plan_summary text,

  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  rejected_reason text,

  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint contribution_percentage_total_check check (
    child_contribution_percentage + parent_contribution_percentage <= 100
    or child_contribution_percentage + parent_contribution_percentage = 100
  )
);

create trigger set_tabung_goals_updated_at
before update on public.tabung_goals
for each row execute function public.set_updated_at();

comment on table public.ai_logs is
'Stores AI agent prompts and responses. Goal Planner Agent v3 uses early-flow input (userRole, tabungType, tabungName, tabungDescription) and stores a normalized structured response.';

comment on column public.tabung_goals.ai_plan is
'Full Goal Planner Agent response JSON. Goal Planner Agent v3 shape includes suggestedGoalAmount, contributionRatioSuggestion, endPeriodSuggestion, recurringTargetSuggestion, milestoneRewardSuggestions, summary, and promptVersion.';

comment on column public.tabung_goals.ai_plan_summary is
'Human-readable summary from Goal Planner Agent output.';

  comment on column public.tabung_goals.period_suggestion_months is
  'Legacy month-oriented period field. Goal Planner Agent v3 may use endPeriodSuggestion.durationUnit other than months; month values are only populated when applicable.';

  comment on column public.tabung_goals.suggested_deadline is
  'Derived deadline date used by the app after combining end period suggestion with user-confirmed schedule details.';

  comment on column public.tabung_goals.recurring_start_date is
  'Start date for recurring contribution tracking and reminder scheduling. Older rows may be backfilled from created_at when this value was not saved originally.';

-- ------------------------------------------------------------
-- 4.5 tabung_requests
-- Child-created Tabung requests for parent approval.
-- Parent can still view missed requests on home page.
-- ------------------------------------------------------------

create table public.tabung_requests (
  id uuid primary key default gen_random_uuid(),
  tabung_id uuid not null references public.tabung_goals(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  parent_id uuid references public.profiles(id) on delete set null,
  family_id uuid not null references public.families(id) on delete cascade,
  status public.request_status not null default 'pending',
  request_message text,
  parent_response text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4.6 milestones
-- Goal Planner Agent milestone suggestions are inserted here.
-- ------------------------------------------------------------

create table public.milestones (
  id uuid primary key default gen_random_uuid(),
  tabung_id uuid not null references public.tabung_goals(id) on delete cascade,
  milestone_amount numeric(12,2) not null check (milestone_amount > 0),
  milestone_label text not null,
  milestone_description text,
  reward_description text,
  status public.milestone_status not null default 'locked',
  unlocked_at timestamptz,
  claimed_at timestamptz,
  created_at timestamptz not null default now()
);

comment on column public.milestones.reward_description is
'Reward suggestion text. Goal Planner Agent v3 milestone payload includes rewardSuggestion per milestone.';

-- ------------------------------------------------------------
-- 4.7 savings_entries
-- Money saved into a Tabung by child or parent.
-- ------------------------------------------------------------

create table public.savings_entries (
  id uuid primary key default gen_random_uuid(),
  tabung_id uuid not null references public.tabung_goals(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  source text not null default 'allowance',
  note text,
  saved_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4.8 payment_transactions
-- Fake bank-transfer-style payment simulation.
--
-- Spending Habit Coach Agent output is stored here:
-- - coach_response
-- - impact_warning
-- - estimated_delay_text
-- - alternative_suggestion
-- ------------------------------------------------------------

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  tabung_id uuid references public.tabung_goals(id) on delete set null,

  amount numeric(12,2) not null check (amount > 0),
  purpose text not null,
  category text,
  bank_transfer_reference text,

  coach_response jsonb,
  impact_warning text,
  recurring_target_reminder text,
  estimated_delay_text text,
  alternative_suggestion text,
  budget_health_tip text,
  should_proceed boolean,
  latitude numeric(10,7),
  longitude numeric(10,7),
  location_accuracy numeric(10,2),
  location_permission_status text not null default 'unknown',
  guessed_place_name text,
  guessed_place_category text,
  guessed_place_confidence text,
  guessed_place_reason text,

  status public.payment_status not null default 'pending_review',
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4.9 recurring_goal_logs
-- Recurring target check result.
--
-- Recurring Goal Reminder Agent output is stored here:
-- - reminder_response JSON
-- - reminder_message
-- - recovery_plan
-- - time_visualization_text
-- - calendar title and description
-- ------------------------------------------------------------

create table public.recurring_goal_logs (
  id uuid primary key default gen_random_uuid(),
  tabung_id uuid not null references public.tabung_goals(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  target_amount numeric(12,2) not null check (target_amount > 0),
  saved_amount numeric(12,2) not null default 0 check (saved_amount >= 0),
  missed_amount numeric(12,2) not null default 0 check (missed_amount >= 0),
  days_left_to_deadline integer,
  status public.recurring_log_status not null,

  reminder_response jsonb,
  reminder_message text,
  recovery_plan text,
  time_visualization_text text,
  calendar_event_title text,
  calendar_event_description text,

  reminder_sent boolean not null default false,
  calendar_event_prepared boolean not null default false,
  created_at timestamptz not null default now(),

  unique (tabung_id, period_start, period_end)
);

-- ------------------------------------------------------------
-- 4.10 notifications
-- In-app notifications.
-- ------------------------------------------------------------

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  family_id uuid references public.families(id) on delete cascade,
  tabung_id uuid references public.tabung_goals(id) on delete cascade,
  title text not null,
  message text not null,
  type public.notification_type not null default 'system',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4.11 calendar_connections
-- Stores Google Calendar connection status.
-- Do not store raw OAuth secrets in frontend-accessible columns.
-- For production, store sensitive tokens securely through backend.
-- ------------------------------------------------------------

create table public.calendar_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'google',
  is_connected boolean not null default false,
  google_calendar_id text,
  connected_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider)
);

create trigger set_calendar_connections_updated_at
before update on public.calendar_connections
for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 4.12 calendar_events
-- Stores planned or synced Google Calendar events.
-- ------------------------------------------------------------

create table public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tabung_id uuid references public.tabung_goals(id) on delete cascade,
  recurring_log_id uuid references public.recurring_goal_logs(id) on delete set null,
  event_type public.calendar_event_type not null,
  title text not null,
  description text,
  start_time timestamptz,
  end_time timestamptz,
  recurrence_rule text,
  timezone text not null default 'Asia/Kuala_Lumpur',
  google_event_id text,
  sync_status public.calendar_sync_status not null default 'pending',
  sync_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_calendar_events_updated_at
before update on public.calendar_events
for each row execute function public.set_updated_at();

create table private.google_calendar_tokens (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  access_token text not null,
  refresh_token text,
  token_expiry timestamptz,
  scope text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
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

create trigger set_google_calendar_tokens_updated_at
before update on private.google_calendar_tokens
for each row execute function private.set_updated_at();

create table private.google_oauth_states (
  state text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'google',
  redirect_uri text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

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

-- ------------------------------------------------------------
-- 4.13 ai_logs
-- Stores AI prompts and responses for traceability.
-- ------------------------------------------------------------

create table public.ai_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  family_id uuid references public.families(id) on delete cascade,
  tabung_id uuid references public.tabung_goals(id) on delete cascade,
  agent_type public.ai_agent_type not null,
  prompt text,
  response text,
  structured_response jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 5. HELPER FUNCTIONS FOR RLS
-- Created after tables to avoid relation-does-not-exist errors.
-- ============================================================

create or replace function public.is_family_member(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
  );
$$;

create or replace function public.is_family_parent(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    join public.profiles p on p.id = fm.user_id
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
      and p.role = 'parent'
  );
$$;

create or replace function public.can_access_tabung(target_tabung_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tabung_goals tg
    join public.family_members fm on fm.family_id = tg.family_id
    where tg.id = target_tabung_id
      and fm.user_id = auth.uid()
  );
$$;

create or replace function public.is_tabung_child(target_tabung_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tabung_goals tg
    where tg.id = target_tabung_id
      and tg.child_id = auth.uid()
  );
$$;

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

grant execute on function public.register_parent_account(text, text, text) to authenticated;

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

grant execute on function public.register_child_account(text, text, text) to authenticated;

-- ============================================================
-- 6. TRIGGERS FOR PROGRESS AND MILESTONES
-- ============================================================

create or replace function public.refresh_tabung_current_amount()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_tabung_id uuid;
begin
  target_tabung_id := coalesce(new.tabung_id, old.tabung_id);

  update public.tabung_goals tg
  set current_amount =
    tg.initial_savings
    + coalesce((
      select sum(se.amount)
      from public.savings_entries se
      where se.tabung_id = target_tabung_id
    ), 0)
    - coalesce((
      select sum(pt.amount)
      from public.payment_transactions pt
      where pt.tabung_id = target_tabung_id
        and pt.status = 'confirmed'
        and coalesce(lower(pt.purpose), '') not like 'deposit to %'
    ), 0)
  where tg.id = target_tabung_id;

  return coalesce(new, old);
end;
$$;

create trigger refresh_tabung_amount_after_savings_insert
after insert on public.savings_entries
for each row execute function public.refresh_tabung_current_amount();

create trigger refresh_tabung_amount_after_savings_update
after update on public.savings_entries
for each row execute function public.refresh_tabung_current_amount();

create trigger refresh_tabung_amount_after_savings_delete
after delete on public.savings_entries
for each row execute function public.refresh_tabung_current_amount();

create or replace function public.unlock_reached_milestones()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.milestones
  set status = 'unlocked',
      unlocked_at = coalesce(unlocked_at, now())
  where tabung_id = new.id
    and status = 'locked'
    and milestone_amount <= new.current_amount;

  if new.current_amount >= new.goal_amount and new.status <> 'completed' then
    update public.tabung_goals
    set status = 'completed',
        completed_at = coalesce(completed_at, now())
    where id = new.id;
  end if;

  return new;
end;
$$;

create trigger unlock_milestones_after_tabung_amount_update
after update of current_amount on public.tabung_goals
for each row execute function public.unlock_reached_milestones();

-- ============================================================
-- 7. INDEXES
-- ============================================================

create index idx_profiles_role on public.profiles(role);

create index idx_families_created_by on public.families(created_by);
create index idx_family_members_family_id on public.family_members(family_id);
create index idx_family_members_user_id on public.family_members(user_id);

create index idx_tabung_goals_family_id on public.tabung_goals(family_id);
create index idx_tabung_goals_child_id on public.tabung_goals(child_id);
create index idx_tabung_goals_created_by on public.tabung_goals(created_by);
create index idx_tabung_goals_status on public.tabung_goals(status);
create index idx_tabung_goals_type on public.tabung_goals(tabung_type);
create index idx_tabung_goals_recurring on public.tabung_goals(recurring_period, recurring_amount);

create index idx_tabung_requests_tabung_id on public.tabung_requests(tabung_id);
create index idx_tabung_requests_family_id on public.tabung_requests(family_id);
create index idx_tabung_requests_status on public.tabung_requests(status);
create index idx_tabung_requests_parent_id on public.tabung_requests(parent_id);

create index idx_milestones_tabung_id on public.milestones(tabung_id);

create index idx_savings_entries_tabung_id on public.savings_entries(tabung_id);
create index idx_savings_entries_user_id on public.savings_entries(user_id);
create index idx_savings_entries_saved_at on public.savings_entries(saved_at);

create index idx_payment_transactions_user_id on public.payment_transactions(user_id);
create index idx_payment_transactions_family_id on public.payment_transactions(family_id);
create index idx_payment_transactions_tabung_id on public.payment_transactions(tabung_id);
create index idx_payment_transactions_status on public.payment_transactions(status);
create index idx_payment_transactions_tabung_created_at on public.payment_transactions(tabung_id, created_at desc);
create index idx_payment_transactions_user_created_at on public.payment_transactions(user_id, created_at desc);

create index idx_recurring_goal_logs_tabung_id on public.recurring_goal_logs(tabung_id);
create index idx_recurring_goal_logs_status on public.recurring_goal_logs(status);

create index idx_notifications_user_id on public.notifications(user_id);
create index idx_notifications_is_read on public.notifications(is_read);
create index idx_notifications_type on public.notifications(type);

create index idx_calendar_connections_user_id on public.calendar_connections(user_id);

create index idx_calendar_events_user_id on public.calendar_events(user_id);
create index idx_calendar_events_tabung_id on public.calendar_events(tabung_id);
create index idx_calendar_events_sync_status on public.calendar_events(sync_status);
create index idx_calendar_events_tabung_sync on public.calendar_events(tabung_id, sync_status, created_at desc);
create index idx_private_google_oauth_states_user_id on private.google_oauth_states(user_id);

create index idx_ai_logs_agent_type on public.ai_logs(agent_type);
create index idx_ai_logs_user_id on public.ai_logs(user_id);
create index idx_ai_logs_tabung_id on public.ai_logs(tabung_id);

-- ============================================================
-- 8. ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.tabung_goals enable row level security;
alter table public.tabung_requests enable row level security;
alter table public.milestones enable row level security;
alter table public.savings_entries enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.recurring_goal_logs enable row level security;
alter table public.notifications enable row level security;
alter table public.calendar_connections enable row level security;
alter table public.calendar_events enable row level security;
alter table public.ai_logs enable row level security;

-- ------------------------------------------------------------
-- profiles policies
-- ------------------------------------------------------------

create policy "Users can view own profile"
on public.profiles for select to authenticated
using (id = auth.uid());

create policy "Users can insert own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Users can update own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- ------------------------------------------------------------
-- families policies
-- ------------------------------------------------------------

create policy "Family members can view families"
on public.families for select to authenticated
using (public.is_family_member(id));

create policy "Users can create families"
on public.families for insert to authenticated
with check (created_by = auth.uid());

create policy "Family parents can update families"
on public.families for update to authenticated
using (public.is_family_parent(id))
with check (public.is_family_parent(id));

-- ------------------------------------------------------------
-- family_members policies
-- ------------------------------------------------------------

create policy "Family members can view family members"
on public.family_members for select to authenticated
using (public.is_family_member(family_id));

create policy "Users can add themselves to family"
on public.family_members for insert to authenticated
with check (user_id = auth.uid());

create policy "Family parents can manage family members"
on public.family_members for update to authenticated
using (public.is_family_parent(family_id))
with check (public.is_family_parent(family_id));

create policy "Family parents can remove family members"
on public.family_members for delete to authenticated
using (public.is_family_parent(family_id));

-- ------------------------------------------------------------
-- tabung_goals policies
-- ------------------------------------------------------------

create policy "Family members can view tabung goals"
on public.tabung_goals for select to authenticated
using (public.is_family_member(family_id));

create policy "Family members can create tabung goals"
on public.tabung_goals for insert to authenticated
with check (
  created_by = auth.uid()
  and public.is_family_member(family_id)
);

create policy "Child or parent can update tabung goals"
on public.tabung_goals for update to authenticated
using (
  child_id = auth.uid()
  or public.is_family_parent(family_id)
)
with check (
  child_id = auth.uid()
  or public.is_family_parent(family_id)
);

create policy "Family parent can delete tabung goals"
on public.tabung_goals for delete to authenticated
using (public.is_family_parent(family_id));

-- ------------------------------------------------------------
-- tabung_requests policies
-- ------------------------------------------------------------

create policy "Family members can view tabung requests"
on public.tabung_requests for select to authenticated
using (public.is_family_member(family_id));

create policy "Family members can create tabung requests"
on public.tabung_requests for insert to authenticated
with check (
  requested_by = auth.uid()
  and public.is_family_member(family_id)
);

create policy "Family parent can update tabung requests"
on public.tabung_requests for update to authenticated
using (public.is_family_parent(family_id))
with check (public.is_family_parent(family_id));

-- ------------------------------------------------------------
-- milestones policies
-- ------------------------------------------------------------

create policy "Family members can view milestones"
on public.milestones for select to authenticated
using (public.can_access_tabung(tabung_id));

create policy "Family members can insert milestones"
on public.milestones for insert to authenticated
with check (public.can_access_tabung(tabung_id));

create policy "Family members can update milestones"
on public.milestones for update to authenticated
using (public.can_access_tabung(tabung_id))
with check (public.can_access_tabung(tabung_id));

-- ------------------------------------------------------------
-- savings_entries policies
-- ------------------------------------------------------------

create policy "Family members can view savings entries"
on public.savings_entries for select to authenticated
using (public.can_access_tabung(tabung_id));

create policy "Family members can insert savings entries"
on public.savings_entries for insert to authenticated
with check (
  user_id = auth.uid()
  and public.can_access_tabung(tabung_id)
);

create policy "Users can update own savings entries"
on public.savings_entries for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own savings entries"
on public.savings_entries for delete to authenticated
using (user_id = auth.uid());

-- ------------------------------------------------------------
-- payment_transactions policies
-- ------------------------------------------------------------

create policy "Family members can view payment transactions"
on public.payment_transactions for select to authenticated
using (public.is_family_member(family_id));

create policy "Users can insert own payment transactions"
on public.payment_transactions for insert to authenticated
with check (
  user_id = auth.uid()
  and public.is_family_member(family_id)
);

create policy "Users can update own payment transactions"
on public.payment_transactions for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- recurring_goal_logs policies
-- ------------------------------------------------------------

create policy "Family members can view recurring logs"
on public.recurring_goal_logs for select to authenticated
using (public.can_access_tabung(tabung_id));

create policy "Family members can insert recurring logs"
on public.recurring_goal_logs for insert to authenticated
with check (public.can_access_tabung(tabung_id));

create policy "Family members can update recurring logs"
on public.recurring_goal_logs for update to authenticated
using (public.can_access_tabung(tabung_id))
with check (public.can_access_tabung(tabung_id));

-- ------------------------------------------------------------
-- notifications policies
-- ------------------------------------------------------------

create policy "Users can view own notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());

create policy "Users can update own notifications"
on public.notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Family members can insert notifications"
on public.notifications for insert to authenticated
with check (
  user_id = auth.uid()
  or family_id is null
  or public.is_family_member(family_id)
);

-- ------------------------------------------------------------
-- calendar_connections policies
-- ------------------------------------------------------------

create policy "Users can view own calendar connection"
on public.calendar_connections for select to authenticated
using (user_id = auth.uid());

create policy "Users can insert own calendar connection"
on public.calendar_connections for insert to authenticated
with check (user_id = auth.uid());

create policy "Users can update own calendar connection"
on public.calendar_connections for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- calendar_events policies
-- ------------------------------------------------------------

create policy "Users can view own calendar events"
on public.calendar_events for select to authenticated
using (user_id = auth.uid());

create policy "Users can insert own calendar events"
on public.calendar_events for insert to authenticated
with check (user_id = auth.uid());

create policy "Users can update own calendar events"
on public.calendar_events for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- ai_logs policies
-- ------------------------------------------------------------

create policy "Family members can view ai logs"
on public.ai_logs for select to authenticated
using (
  user_id = auth.uid()
  or public.is_family_member(family_id)
  or public.can_access_tabung(tabung_id)
);

create policy "Authenticated users can insert ai logs"
on public.ai_logs for insert to authenticated
with check (
  user_id = auth.uid()
  or public.is_family_member(family_id)
  or public.can_access_tabung(tabung_id)
);

-- ============================================================
-- 9. DASHBOARD VIEW
-- ============================================================

create or replace view public.tabung_dashboard_view as
select
  tg.id as tabung_id,
  tg.family_id,
  tg.child_id,
  tg.created_by,
  tg.tabung_type,
  tg.tabung_name,
  tg.goal_amount,
  tg.current_amount,
  case
    when tg.goal_amount > 0 then round((tg.current_amount / tg.goal_amount) * 100, 2)
    else 0
  end as progress_percentage,
  tg.desired_deadline,
  tg.deadline,
  tg.suggested_deadline,
  tg.status,
  tg.recurring_amount,
  tg.recurring_period,
  tg.child_contribution_amount,
  tg.parent_contribution_amount,
  tg.child_contribution_percentage,
  tg.parent_contribution_percentage,
  tg.period_suggestion_months,
  tg.difficulty_level,
  tg.ai_plan_summary,
  tg.created_at,
  tg.updated_at
from public.tabung_goals tg;

-- ============================================================
-- 10. OPTIONAL STARTER DATA
-- This data does not reference auth users, so no seed users here.
-- Users should be created from Supabase Auth first.
-- ============================================================

-- No starter users included because Supabase Auth user IDs are required.

-- ============================================================
-- 11. IMPLEMENTATION NOTES
-- ============================================================

-- Recommended setup order:
--
-- 1. Run this SQL file in Supabase SQL Editor.
-- 2. Enable Email Auth in Supabase Authentication.
-- 3. Create parent and child test users through Supabase Auth.
-- 4. Insert their profile rows into public.profiles.
-- 5. Parent creates a family.
-- 6. Insert parent and child into public.family_members.
-- 7. Child creates a tabung_goals row with status = 'pending'.
-- 8. Store Goal Planner Agent output in:
--    - tabung_goals.recurring_amount
--    - tabung_goals.recurring_period
--    - tabung_goals.period_suggestion_months
--    - tabung_goals.child_contribution_amount
--    - tabung_goals.parent_contribution_amount
--    - tabung_goals.ai_plan
-- 9. Insert milestoneSuggestions into public.milestones.
-- 10. Insert a tabung_requests row so parent can approve.
-- 11. Use payment_transactions for fake payment review and confirmation.
-- 12. Use recurring_goal_logs and calendar_events for missed target reminders.
--
-- ============================================================
-- End of schema
-- ============================================================
