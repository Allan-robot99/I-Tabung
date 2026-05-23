-- Fix invite code generation to avoid pgcrypto function issues on remote.
-- Also ensures pgcrypto exists for other UUID helpers.

create extension if not exists pgcrypto;

create or replace function public.generate_invite_code()
returns text
language sql
as $$
  select upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
$$;
