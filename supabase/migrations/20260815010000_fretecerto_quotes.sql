create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  customer_name text not null,
  seller_name text not null default '',
  origin text not null,
  destination text not null,
  cargo_type text not null,
  quote_type text not null default 'Orcamento',
  total_weight_kg numeric not null default 0,
  total_volume_m3 numeric not null default 0,
  invoice_value numeric not null default 0,
  distance_km numeric not null default 0,
  total_distance_km numeric not null default 0,
  suggested_vehicle text not null default '',
  body_type text not null default '',
  commercial_value numeric not null default 0,
  operational_cost numeric not null default 0,
  minimum_antt_value numeric not null default 0,
  is_below_antt boolean not null default false,
  antt_cargo_type text not null default 'Carga geral',
  antt_axles integer not null default 2,
  is_diesel_vehicle boolean not null default true,
  is_national_trip boolean not null default true,
  is_full_truckload boolean not null default true,
  is_vehicle_composition boolean not null default true,
  is_high_performance boolean not null default false,
  has_empty_return boolean not null default false,
  validity_days integer not null default 7,
  status text not null default 'Pronto para proposta',
  created_by uuid references auth.users(id) on delete set null
);

create index if not exists quotes_created_at_idx
  on public.quotes (created_at desc);

create index if not exists quotes_customer_name_idx
  on public.quotes (customer_name);

drop trigger if exists quotes_set_updated_at on public.quotes;
create trigger quotes_set_updated_at
before update on public.quotes
for each row execute function public.set_updated_at();

alter table public.quotes enable row level security;

drop policy if exists "quotes authenticated read" on public.quotes;
create policy "quotes authenticated read"
on public.quotes
for select
to authenticated
using (true);

drop policy if exists "quotes authenticated insert" on public.quotes;
create policy "quotes authenticated insert"
on public.quotes
for insert
to authenticated
with check (auth.uid() is not null);

drop policy if exists "quotes authenticated update" on public.quotes;
create policy "quotes authenticated update"
on public.quotes
for update
to authenticated
using (true)
with check (auth.uid() is not null);
