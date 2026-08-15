create or replace view public.admin_quotes_overview as
select
  q.id,
  q.created_at,
  q.customer_name,
  q.seller_name,
  q.quote_type,
  q.origin,
  q.destination,
  q.cargo_type,
  q.antt_cargo_type,
  q.antt_axles,
  q.total_weight_kg,
  q.total_volume_m3,
  q.total_distance_km,
  q.suggested_vehicle,
  q.body_type,
  q.operational_cost,
  q.minimum_antt_value,
  q.commercial_value,
  q.commercial_value - q.operational_cost as gross_margin_value,
  case
    when q.commercial_value = 0 then 0
    else round(((q.commercial_value - q.operational_cost) / q.commercial_value) * 100, 2)
  end as gross_margin_percent,
  q.is_below_antt,
  case
    when q.minimum_antt_value <= 0 then 'Piso ANTT pendente'
    when q.is_below_antt then 'Risco: abaixo do piso'
    else 'Conferido'
  end as antt_status,
  q.status
from public.quotes q;

create or replace view public.admin_quotes_daily_summary as
select
  date_trunc('day', created_at)::date as day,
  count(*) as quotes_count,
  count(*) filter (where quote_type = 'Proposta') as proposals_count,
  count(*) filter (where quote_type = 'Orcamento') as budgets_count,
  count(*) filter (where is_below_antt) as antt_risk_count,
  round(coalesce(sum(commercial_value), 0), 2) as total_commercial_value,
  round(coalesce(avg(commercial_value), 0), 2) as average_commercial_value,
  round(coalesce(sum(commercial_value - operational_cost), 0), 2) as total_gross_margin
from public.quotes
group by 1
order by day desc;

create or replace view public.admin_quotes_customer_summary as
select
  customer_name,
  count(*) as quotes_count,
  max(created_at) as last_quote_at,
  round(coalesce(sum(commercial_value), 0), 2) as total_commercial_value,
  round(coalesce(avg(commercial_value), 0), 2) as average_commercial_value,
  count(*) filter (where is_below_antt) as antt_risk_count,
  count(*) filter (where minimum_antt_value <= 0) as pending_antt_count
from public.quotes
group by customer_name
order by last_quote_at desc;

create or replace view public.admin_quotes_antt_risk as
select
  id,
  created_at,
  customer_name,
  origin,
  destination,
  antt_cargo_type,
  antt_axles,
  minimum_antt_value,
  commercial_value,
  commercial_value - minimum_antt_value as difference_to_floor,
  case
    when minimum_antt_value <= 0 then 'Informar piso oficial'
    when is_below_antt then 'Corrigir antes de enviar'
    else 'Ok'
  end as action_required
from public.quotes
where minimum_antt_value <= 0
   or is_below_antt
order by created_at desc;

grant select on public.admin_quotes_overview to authenticated;
grant select on public.admin_quotes_daily_summary to authenticated;
grant select on public.admin_quotes_customer_summary to authenticated;
grant select on public.admin_quotes_antt_risk to authenticated;
