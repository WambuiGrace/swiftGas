-- Drivers table + RLS

-- Ensure PostGIS (for geography Point)
create extension if not exists postgis;

-- Driver status enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'driver_status') then
    create type public.driver_status as enum ('active', 'suspended', 'offline');
  end if;
end$$;

-- Table
create table if not exists public.drivers (
  driver_id text primary key,                                                     -- doc ID
  user_id text not null unique references public.users(user_id) on delete cascade,-- owner user
  supplier_id text references public.suppliers(supplier_id) on delete set null,   -- ref to suppliers.supplier_id

  name text not null,
  phone text,
  photo_url text,

  vehicle_number text,
  vehicle_type text,
  license_number text,
  national_id text,

  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),
  total_deliveries integer not null default 0,

  current_location geography(Point, 4326), -- real-time
  is_available boolean not null default false,
  is_verified boolean not null default false,
  status public.driver_status not null default 'offline',

  earnings jsonb not null default '{"today":0,"thisWeek":0,"thisMonth":0,"total":0}'::jsonb
    check (jsonb_typeof(earnings) = 'object'),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Updated-at trigger (idempotent)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_drivers_set_updated_at on public.drivers;
create trigger trg_drivers_set_updated_at
before update on public.drivers
for each row execute function public.set_updated_at();

-- Useful indexes
create index if not exists idx_drivers_user_id on public.drivers(user_id);
create index if not exists idx_drivers_supplier_id on public.drivers(supplier_id);
create index if not exists idx_drivers_is_available on public.drivers(is_available);
create index if not exists idx_drivers_status on public.drivers(status);
create index if not exists idx_drivers_current_location_gix on public.drivers using gist (current_location);

comment on table public.drivers is 'Drivers linked to users and suppliers.';
comment on column public.drivers.earnings is 'Object: {today,thisWeek,thisMonth,total}.';

-- Prevent privilege escalation by non-admins
create or replace function public.prevent_driver_privilege_escalation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if not public.is_admin() then
    if tg_op = 'UPDATE' then
      if new.user_id is distinct from old.user_id then
        raise exception 'Not allowed to change user_id';
      end if;
      if new.supplier_id is distinct from old.supplier_id then
        raise exception 'Not allowed to change supplier_id';
      end if;
      if new.is_verified is distinct from old.is_verified then
        raise exception 'Not allowed to change is_verified';
      end if;
      if new.status is distinct from old.status then
        raise exception 'Not allowed to change status';
      end if;
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_drivers_no_escalation on public.drivers;
create trigger trg_drivers_no_escalation
before update on public.drivers
for each row execute function public.prevent_driver_privilege_escalation();

-- RLS
alter table public.drivers enable row level security;

-- SELECT
drop policy if exists "Drivers can read self" on public.drivers;
create policy "Drivers can read self"
on public.drivers
for select
to authenticated
using (user_id = public.jwt_uid_text());

drop policy if exists "Suppliers can read their drivers" on public.drivers;
create policy "Suppliers can read their drivers"
on public.drivers
for select
to authenticated
using (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.drivers.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Admins can read all drivers" on public.drivers;
create policy "Admins can read all drivers"
on public.drivers
for select
to authenticated
using (public.is_admin());

-- INSERT
drop policy if exists "Drivers can insert self" on public.drivers;
create policy "Drivers can insert self"
on public.drivers
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Suppliers can insert drivers for own supplier" on public.drivers;
create policy "Suppliers can insert drivers for own supplier"
on public.drivers
for insert
to authenticated
with check (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.drivers.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Admins can insert any driver" on public.drivers;
create policy "Admins can insert any driver"
on public.drivers
for insert
to authenticated
with check (public.is_admin());

-- UPDATE
drop policy if exists "Drivers can update self" on public.drivers;
create policy "Drivers can update self"
on public.drivers
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Suppliers can update their drivers" on public.drivers;
create policy "Suppliers can update their drivers"
on public.drivers
for update
to authenticated
using (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.drivers.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
)
with check (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.drivers.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Admins can update any driver" on public.drivers;
create policy "Admins can update any driver"
on public.drivers
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE
drop policy if exists "Admins can delete any driver" on public.drivers;
create policy "Admins can delete any driver"
on public.drivers
for delete
to authenticated
using (public.is_admin());

drop policy if exists "Suppliers can delete their drivers" on public.drivers;
create policy "Suppliers can delete their drivers"
on public.drivers
for delete
to authenticated
using (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.drivers.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
);