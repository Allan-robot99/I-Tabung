alter table public.payment_transactions
add column if not exists latitude numeric(10,7),
add column if not exists longitude numeric(10,7),
add column if not exists location_accuracy numeric(10,2),
add column if not exists location_permission_status text not null default 'unknown',
add column if not exists guessed_place_name text,
add column if not exists guessed_place_category text,
add column if not exists guessed_place_confidence text;

create index if not exists idx_payment_transactions_tabung_created_at
on public.payment_transactions(tabung_id, created_at desc);

create index if not exists idx_payment_transactions_user_created_at
on public.payment_transactions(user_id, created_at desc);
