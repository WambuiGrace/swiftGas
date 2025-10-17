-- Enable required extensions (idempotent)
create extension if not exists postgis;

-- Order status enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'pending',
      'accepted',
      'preparing',
      'assigned',
      'picked_up',
      'out_for_delivery',
      'delivered',
      'cancelled'
    );
  end if;
end$$;

-- Orders table
create table if not exists public.orders (
  order_id text primary key,

  -- Relations
  user_id text not null references public.users(user_id) on delete cascade,      -- customer
  supplier_id text references public.users(user_id) on delete set null,          -- supplier (nullable until assigned)
  driver_id text references public.users(user_id) on delete set null,            -- driver (nullable until assigned)

  -- Order details
  cylinder_size text not null,
  quantity integer not null check (quantity > 0),
  total_price numeric(12,2) not null check (total_price >= 0),

  delivery_address jsonb not null default '{}'::jsonb check (jsonb_typeof(delivery_address) = 'object'),
  scheduled_time timestamptz,

  status public.order_status not null default 'pending',
  payment_status text,
  payment_method text,
  transaction_id text,

  driver_location geography(Point, 4326),

  status_history jsonb not null default '[]'::jsonb check (jsonb_typeof(status_history) = 'array'),

  supplier_accepted_at timestamptz,
  assigned_to_driver_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,

  points_earned integer not null default 0 check (points_earned >= 0),
  rating numeric(3,2) check (rating >= 0 and rating <= 5),
  feedback text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Reuse/update the updated_at trigger function if needed (defined in users migration)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_orders_set_updated_at on public.orders;
create trigger trg_orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_orders_user_id on public.orders(user_id);
create index if not exists idx_orders_supplier_id on public.orders(supplier_id);
create index if not exists idx_orders_driver_id on public.orders(driver_id);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_scheduled_time on public.orders(scheduled_time);
create index if not exists idx_orders_created_at on public.orders(created_at);
create index if not exists idx_orders_driver_location_gix on public.orders using gist (driver_location);

comment on table public.orders is 'Customer orders and lifecycle, linked to users (customer/supplier/driver).';
comment on column public.orders.status_history is 'Array of {status, timestamp, updatedBy} JSON objects.';
comment on column public.orders.driver_location is 'Driver live location as geography(Point,4326).';

-- Helper for policies (idempotent)
create or replace function public.jwt_uid_text()
returns text
language sql
stable
as $$
  -- Prefer the JWT 'sub' claim if present; otherwise fallback to auth.uid()
  select coalesce(nullif(auth.jwt() ->> 'sub', ''), auth.uid()::text)
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.users u
    where u.user_id = public.jwt_uid_text() and u.user_type = 'admin'::public.user_type
  );
$$;

-- RLS
alter table public.orders enable row level security;

-- SELECT policies
drop policy if exists "Customers can read own orders" on public.orders;
create policy "Customers can read own orders"
on public.orders
for select
to authenticated
using (user_id = public.jwt_uid_text());

drop policy if exists "Suppliers can read assigned orders" on public.orders;
create policy "Suppliers can read assigned orders"
on public.orders
for select
to authenticated
using (supplier_id = public.jwt_uid_text());

drop policy if exists "Drivers can read assigned orders" on public.orders;
create policy "Drivers can read assigned orders"
on public.orders
for select
to authenticated
using (driver_id = public.jwt_uid_text());

drop policy if exists "Admins can read all orders" on public.orders;
create policy "Admins can read all orders"
on public.orders
for select
to authenticated
using (public.is_admin());

-- INSERT policies
drop policy if exists "Customers can insert their own orders" on public.orders;
create policy "Customers can insert their own orders"
on public.orders
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can insert any order" on public.orders;
create policy "Admins can insert any order"
on public.orders
for insert
to authenticated
with check (public.is_admin());

-- UPDATE policies
drop policy if exists "Customers can update own orders" on public.orders;
create policy "Customers can update own orders"
on public.orders
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Suppliers can update assigned orders" on public.orders;
create policy "Suppliers can update assigned orders"
on public.orders
for update
to authenticated
using (supplier_id = public.jwt_uid_text())
with check (supplier_id = public.jwt_uid_text());

drop policy if exists "Drivers can update assigned orders" on public.orders;
create policy "Drivers can update assigned orders"
on public.orders
for update
to authenticated
using (driver_id = public.jwt_uid_text())
with check (driver_id = public.jwt_uid_text());

drop policy if exists "Admins can update any order" on public.orders;
create policy "Admins can update any order"
on public.orders
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE policy (admin only)
drop policy if exists "Admins can delete any order" on public.orders;
create policy "Admins can delete any order"
on public.orders
for delete
to authenticated
using (public.is_admin());