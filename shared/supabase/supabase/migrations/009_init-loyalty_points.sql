-- Loyalty points + RLS

create table if not exists public.loyalty_points (
  points_id text primary key,                               -- doc ID
  title text not null,
  description text,
  points_required integer not null check (points_required >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0), -- in KES
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh (function defined in 001_init-users.sql)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_loyalty_points_set_updated_at on public.loyalty_points;
create trigger trg_loyalty_points_set_updated_at
before update on public.loyalty_points
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_loyalty_points_active on public.loyalty_points(is_active);
create index if not exists idx_loyalty_points_required on public.loyalty_points(points_required);

comment on table public.loyalty_points is 'Loyalty rewards definitions (points thresholds and discounts).';
comment on column public.loyalty_points.discount_amount is 'Discount in KES.';

-- RLS
alter table public.loyalty_points enable row level security;

-- Read: any authenticated user can read active rewards
drop policy if exists "Anyone authenticated can read active loyalty points" on public.loyalty_points;
create policy "Anyone authenticated can read active loyalty points"
on public.loyalty_points
for select
to authenticated
using (is_active = true);

-- Read: admins can read all
drop policy if exists "Admins can read all loyalty points" on public.loyalty_points;
create policy "Admins can read all loyalty points"
on public.loyalty_points
for select
to authenticated
using (public.is_admin());

-- Insert: admin only
drop policy if exists "Admins can insert loyalty points" on public.loyalty_points;
create policy "Admins can insert loyalty points"
on public.loyalty_points
for insert
to authenticated
with check (public.is_admin());

-- Update: admin only
drop policy if exists "Admins can update loyalty points" on public.loyalty_points;
create policy "Admins can update loyalty points"
on public.loyalty_points
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete loyalty points" on public.loyalty_points;
create policy "Admins can delete loyalty points"
on public.loyalty_points
for delete
to authenticated
using (public.is_admin());