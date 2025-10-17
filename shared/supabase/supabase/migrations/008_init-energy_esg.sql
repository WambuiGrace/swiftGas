-- Energy metrics + RLS

create table if not exists public.energy_metrics (
  metric_id text primary key,                                       -- doc ID

  gas_type_id text references public.gas_types(gas_type_id) on delete set null,
  total_sold_kg numeric(12,2) not null default 0 check (total_sold_kg >= 0),
  estimated_emissions numeric(14,3) not null default 0 check (estimated_emissions >= 0),
  green_energy_credits numeric(12,2) not null default 0 check (green_energy_credits >= 0),
  refilled_cylinders integer not null default 0 check (refilled_cylinders >= 0),
  recycled_cylinders integer not null default 0 check (recycled_cylinders >= 0),

  data_period text not null,                                        -- e.g. "2025-Q1"
  collected_by text not null references public.users(user_id) on delete restrict,
  created_at timestamptz not null default now(),

  -- Ensure one record per gas_type_id + period
  constraint energy_metrics_unique_period unique (gas_type_id, data_period)
);

-- Indexes
create index if not exists idx_energy_metrics_gas_type on public.energy_metrics(gas_type_id);
create index if not exists idx_energy_metrics_period on public.energy_metrics(data_period);
create index if not exists idx_energy_metrics_created_at on public.energy_metrics(created_at);

comment on table public.energy_metrics is 'Aggregated ESG/energy metrics per gas type and period.';
comment on column public.energy_metrics.estimated_emissions is 'CO2e estimate.';
comment on column public.energy_metrics.green_energy_credits is 'Credits earned via eco initiatives.';

-- RLS
alter table public.energy_metrics enable row level security;

-- Read: any authenticated user can read metrics
drop policy if exists "Anyone authenticated can read energy metrics" on public.energy_metrics;
create policy "Anyone authenticated can read energy metrics"
on public.energy_metrics
for select
to authenticated
using (true);

-- Insert: admins only; enforce collected_by is caller
drop policy if exists "Admins can insert energy metrics" on public.energy_metrics;
create policy "Admins can insert energy metrics"
on public.energy_metrics
for insert
to authenticated
with check (public.is_admin() and collected_by = public.jwt_uid_text());

-- Update: admins only
drop policy if exists "Admins can update energy metrics" on public.energy_metrics;
create policy "Admins can update energy metrics"
on public.energy_metrics
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admins only
drop policy if exists "Admins can delete energy metrics" on public.energy_metrics;
create policy "Admins can delete energy metrics"
on public.energy_metrics
for delete
to authenticated
using (public.is_admin());