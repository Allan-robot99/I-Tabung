update public.tabung_goals
set recurring_start_date = coalesce(recurring_start_date, created_at::date)
where recurring_start_date is null
  and recurring_amount is not null
  and recurring_period is not null;
