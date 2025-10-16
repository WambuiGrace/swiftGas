-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists postgis;

-- User type enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_type') then
    create type public.user_type as enum ('customer', 'supplier', 'driver', 'admin');
  end if;
end$$;

-- Users table (user_id = Clerk userId)
create table if not exists public.users (
  user_id text primary key,                      -- Clerk user ID as PK
  clerk_id text not null unique,                 -- Clerk user ID (unique)
  user_type public.user_type not null,           -- customer | supplier | driver | admin

  name text not null,
  email text unique,
  phone text,
  photo_url text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  fcm_token text,
  is_profile_complete boolean not null default false,

  -- Customers
  loyalty_points integer not null default 0,
  addresses jsonb not null default '[]'::jsonb,  -- array of address objects

  -- Suppliers
  business_name text,
  business_license text,
  operating_zones text[] not null default '{}',
  is_verified boolean not null default false,

  -- Drivers
  supplier_id text references public.users(user_id) on delete set null, -- ref to supplier user
  vehicle_number text,
  license_number text,
  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),
  total_deliveries integer not null default 0,
  is_available boolean not null default false,
  current_location geography(Point, 4326)       -- PostGIS geography point
);

-- Updated-at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_users_set_updated_at on public.users;
create trigger trg_users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- Useful indexes
-- Fast geo queries for drivers
create index if not exists idx_users_current_location_gix
  on public.users using gist (current_location);

-- Filter-by-role indexes
create index if not exists idx_users_user_type on public.users(user_type);

-- Quick lookups
create index if not exists idx_users_phone on public.users(phone);
create index if not exists idx_users_email on public.users(email);

comment on table public.users is 'Users from Clerk. Includes customer, supplier, driver, admin profiles.';
comment on column public.users.addresses is 'JSONB array of address objects for customers.';
comment on column public.users.operating_zones is 'Text array of zone names for suppliers.';
comment on column public.users.current_location is 'Driver real-time location as geography(Point,4326).';