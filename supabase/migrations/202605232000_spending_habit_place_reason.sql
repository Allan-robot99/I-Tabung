alter table public.payment_transactions
add column if not exists guessed_place_reason text;
