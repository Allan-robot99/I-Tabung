-- Goal Planner idempotency storage
create table if not exists public.agent_idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  idempotency_key text not null unique,
  agent_type public.ai_agent_type not null,
  request_hash text not null,
  request_body jsonb not null,
  response_body jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_agent_idempotency_agent_type on public.agent_idempotency_keys(agent_type);
create index if not exists idx_agent_idempotency_created_at on public.agent_idempotency_keys(created_at);

drop trigger if exists set_agent_idempotency_updated_at on public.agent_idempotency_keys;

drop trigger if exists set_agent_idempotency_updated_at on public.agent_idempotency_keys;

create trigger set_agent_idempotency_updated_at
before update on public.agent_idempotency_keys
for each row execute function public.set_updated_at();

alter table public.agent_idempotency_keys enable row level security;

drop policy if exists "Service role manages idempotency keys" on public.agent_idempotency_keys;

create policy "Service role manages idempotency keys"
on public.agent_idempotency_keys
for all to authenticated
using (false)
with check (false);
