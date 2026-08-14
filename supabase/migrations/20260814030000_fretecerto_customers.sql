create extension if not exists pgcrypto;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  type text not null check (type in ('company', 'person')),
  document text not null unique,
  name text not null,
  trade_name text not null default '',
  email text not null default '',
  phone text not null default '',
  city text not null default '',
  address text not null default '',
  status text not null default '',
  main_activity text not null default ''
);

create index if not exists customers_created_at_idx
  on public.customers (created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

alter table public.customers enable row level security;

drop policy if exists "customers demo read" on public.customers;
create policy "customers authenticated read"
on public.customers
for select
to authenticated
using (true);

drop policy if exists "customers demo insert" on public.customers;
create policy "customers authenticated insert"
on public.customers
for insert
to authenticated
with check (true);

drop policy if exists "customers demo update" on public.customers;
create policy "customers authenticated update"
on public.customers
for update
to authenticated
using (true)
with check (true);
