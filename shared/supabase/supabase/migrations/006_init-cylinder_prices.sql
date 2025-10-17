-- Cylinder prices + RLS

-- Table
create table if not exists public.cylinder_prices (
  price_id text primary key,                              -- doc ID
  size text not null,                                     -- e.g. '6kg', '13kg'
  price numeric(12,2) not null check (price >= 0),
  refill_price numeric(12,2) check (refill_price >= 0),
  delivery_fee numeric(12,2) not null default 0 check (delivery_fee >= 0),

  code text references public.gas_types(code) on update cascade on delete set null, -- ref Gas Type code
  cylinder_id text,                                         -- ref to Cylinder (FK can be added later if needed)

  is_available boolean not null default true,
  description text,

  effective_from timestamptz,
  effective_to timestamptz,

  regional_adjustment numeric(12,2) not null default 0,     -- zone price offset

  updated_by text not null,                                 -- admin/supplier user_id
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh (function exists in users migration)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_cylinder_prices_set_updated_at on public.cylinder_prices;
create trigger trg_cylinder_prices_set_updated_at
before update on public.cylinder_prices
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_cylinder_prices_code on public.cylinder_prices(code);
create index if not exists idx_cylinder_prices_size on public.cylinder_prices(size);
create index if not exists idx_cylinder_prices_available on public.cylinder_prices(is_available);
create index if not exists idx_cylinder_prices_effective_from on public.cylinder_prices(effective_from);
create index if not exists idx_cylinder_prices_effective_to on public.cylinder_prices(effective_to);

comment on table public.cylinder_prices is 'Prices for cylinders (sale/refill/delivery), optionally adjusted by region.';
comment on column public.cylinder_prices.regional_adjustment is 'Numeric offset applied to base price for delivery zones.';

-- RLS
alter table public.cylinder_prices enable row level security;

-- Read: any authenticated user can read prices
drop policy if exists "Anyone authenticated can read cylinder prices" on public.cylinder_prices;
create policy "Anyone authenticated can read cylinder prices"
on public.cylinder_prices
for select
to authenticated
using (true);

-- Insert: only admins or users who are suppliers; enforce they set updated_by to themselves
drop policy if exists "Admins or suppliers can insert cylinder prices" on public.cylinder_prices;
create policy "Admins or suppliers can insert cylinder prices"
on public.cylinder_prices
for insert
to authenticated
with check (
  public.is_admin()
  or (
    exists (select 1 from public.suppliers s where s.user_id = public.jwt_uid_text())
    and updated_by = public.jwt_uid_text()
  )
);

-- Update: only admins or suppliers; suppliers can only update rows they last updated
drop policy if exists "Admins or suppliers can update cylinder prices" on public.cylinder_prices;
create policy "Admins or suppliers can update cylinder prices"
on public.cylinder_prices
for update
to authenticated
using (
  public.is_admin()
  or (
    exists (select 1 from public.suppliers s where s.user_id = public.jwt_uid_text())
    and updated_by = public.jwt_uid_text()
  )
)
with check (
  public.is_admin()
  or (
    exists (select 1 from public.suppliers s where s.user_id = public.jwt_uid_text())
    and updated_by = public.jwt_uid_text()
  )
);

-- Delete: admin only
drop policy if exists "Admins can delete cylinder prices" on public.cylinder_prices;
create policy "Admins can delete cylinder prices"
on public.cylinder_prices
for delete
to authenticated
using (public.is_admin());