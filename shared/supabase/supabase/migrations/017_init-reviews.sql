-- Reviews + RLS

-- Enum for review type
do $$
begin
  if not exists (select 1 from pg_type where typname = 'review_type') then
    create type public.review_type as enum ('driver_review', 'service_review');
  end if;
end$$;

create table if not exists public.reviews (
  review_id text primary key,                                                    -- doc ID
  order_id text not null references public.orders(order_id) on delete cascade,   -- target order
  customer_id text not null references public.users(user_id) on delete cascade,  -- reviewer (user)
  driver_id text references public.drivers(driver_id) on delete set null,        -- optional (driver reviews)
  supplier_id text references public.suppliers(supplier_id) on delete set null,  -- optional (service reviews)
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  type public.review_type not null,
  created_at timestamptz not null default now(),

  -- At most one review per order per type (e.g., one driver review and one service review)
  constraint reviews_unique_order_type unique (order_id, type)
);

-- Indexes
create index if not exists idx_reviews_order on public.reviews(order_id);
create index if not exists idx_reviews_customer on public.reviews(customer_id);
create index if not exists idx_reviews_driver on public.reviews(driver_id);
create index if not exists idx_reviews_supplier on public.reviews(supplier_id);
create index if not exists idx_reviews_type on public.reviews(type);
create index if not exists idx_reviews_created_at on public.reviews(created_at);

comment on table public.reviews is 'Customer reviews for drivers or overall service, per order.';
comment on column public.reviews.type is 'driver_review or service_review';

-- RLS
alter table public.reviews enable row level security;

-- Read: any authenticated user can read reviews
drop policy if exists "Anyone authenticated can read reviews" on public.reviews;
create policy "Anyone authenticated can read reviews"
on public.reviews
for select
to authenticated
using (true);

-- Insert: only the customer who owns the order; ensure customer_id matches caller and order belongs to caller
drop policy if exists "Customers can insert own order reviews" on public.reviews;
create policy "Customers can insert own order reviews"
on public.reviews
for insert
to authenticated
with check (
  customer_id = public.jwt_uid_text()
  and exists (
    select 1 from public.orders o
    where o.order_id = public.reviews.order_id
      and o.user_id = public.jwt_uid_text()
  )
);

-- Admins can insert any (e.g., backfills)
drop policy if exists "Admins can insert any review" on public.reviews;
create policy "Admins can insert any review"
on public.reviews
for insert
to authenticated
with check (public.is_admin());

-- Update: customers can update their own review; admins can update any
drop policy if exists "Customers can update their reviews" on public.reviews;
create policy "Customers can update their reviews"
on public.reviews
for update
to authenticated
using (customer_id = public.jwt_uid_text())
with check (customer_id = public.jwt_uid_text());

drop policy if exists "Admins can update any review" on public.reviews;
create policy "Admins can update any review"
on public.reviews
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete reviews" on public.reviews;
create policy "Admins can delete reviews"
on public.reviews
for delete
to authenticated
using (public.is_admin());