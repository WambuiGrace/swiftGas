-- Gas types (reference data)
create table if not exists public.gas_types (
  gas_type_id text primary key,                      -- doc ID
  code text not null unique,                         -- short code (e.g., 'LPG-13KG')
  weight_kg numeric(6,2) not null check (weight_kg > 0),
  base_refill_cost numeric(12,2) not null check (base_refill_cost >= 0),
  last_updated timestamptz not null default now(),
  is_active boolean not null default true
);

-- Keep last_updated fresh
create or replace function public.set_last_updated()
returns trigger language plpgsql as $$
begin
  new.last_updated = now();
  return new;
end$$;

drop trigger if exists trg_gas_types_set_last_updated on public.gas_types;
create trigger trg_gas_types_set_last_updated
before update on public.gas_types
for each row execute function public.set_last_updated();

-- Indexes
create index if not exists idx_gas_types_active on public.gas_types(is_active);
create index if not exists idx_gas_types_code on public.gas_types(code);

comment on table public.gas_types is 'Reference catalog of gas types and base refill costs.';

-- RLS: Gas types (read for all authenticated; write for admins)
alter table public.gas_types enable row level security;

drop policy if exists "Anyone authenticated can read gas types" on public.gas_types;
create policy "Anyone authenticated can read gas types"
on public.gas_types
for select
to authenticated
using (true);

drop policy if exists "Admins can insert gas types" on public.gas_types;
create policy "Admins can insert gas types"
on public.gas_types
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Admins can update gas types" on public.gas_types;
create policy "Admins can update gas types"
on public.gas_types
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can delete gas types" on public.gas_types;
create policy "Admins can delete gas types"
on public.gas_types
for delete
to authenticated
using (public.is_admin());