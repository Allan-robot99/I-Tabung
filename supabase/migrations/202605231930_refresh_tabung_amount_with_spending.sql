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
