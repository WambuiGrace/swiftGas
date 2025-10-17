-- Suppliers table
create table if not exists public.suppliers (
  supplier_id text primary key,                                            -- doc ID
  user_id text not null unique references public.users(user_id) on delete cascade, -- owner (users.user_id)

  business_name text not null,
  business_license text,
  contact_person text,
  phone text,
  email text,
  address text,

  operating_zones text[] not null default '{}',                            -- array of zone names
  is_verified boolean not null default false,
  is_active boolean not null default true,

  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),
  total_orders integer not null default 0,

  inventory jsonb not null default '[]'::jsonb                             -- array of objects
    check (jsonb_typeof(inventory) = 'array'),

  drivers text[] not null default '{}',                                    -- array of driver userIds

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_suppliers_set_updated_at on public.suppliers;
create trigger trg_suppliers_set_updated_at
before update on public.suppliers
for each row execute function public.set_updated_at();

-- Useful indexes
create index if not exists idx_suppliers_user_id on public.suppliers(user_id);
create index if not exists idx_suppliers_active on public.suppliers(is_active);
create index if not exists idx_suppliers_verified on public.suppliers(is_verified);
create index if not exists idx_suppliers_operating_zones on public.suppliers using gin (operating_zones);

comment on table public.suppliers is 'Supplier profiles owned by a user.';
comment on column public.suppliers.inventory is 'JSONB array of {cylinderId,size,quantity,lowStockThreshold,price}.';

-- Prevent privilege escalation for non-admins (e.g., flipping verification/ownership)
create or replace function public.prevent_supplier_privilege_escalation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  -- Non-admins cannot change ownership or verification/active flags
  if not public.is_admin() then
    if new.user_id is distinct from old.user_id then
      raise exception 'Not allowed to change user_id';
    end if;
    if new.is_verified is distinct from old.is_verified then
      raise exception 'Not allowed to change is_verified';
    end if;
    if new.is_active is distinct from old.is_active then
      raise exception 'Not allowed to change is_active';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_suppliers_no_escalation on public.suppliers;
create trigger trg_suppliers_no_escalation
before update on public.suppliers
for each row execute function public.prevent_supplier_privilege_escalation();

-- RLS: Suppliers
alter table public.suppliers enable row level security;

-- SELECT
drop policy if exists "Suppliers can read own supplier" on public.suppliers;
create policy "Suppliers can read own supplier"
on public.suppliers
for select
to authenticated
using (user_id = public.jwt_uid_text());

drop policy if exists "Admins can read all suppliers" on public.suppliers;
create policy "Admins can read all suppliers"
on public.suppliers
for select
to authenticated
using (public.is_admin());

-- INSERT
drop policy if exists "Suppliers can insert own supplier" on public.suppliers;
create policy "Suppliers can insert own supplier"
on public.suppliers
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can insert any supplier" on public.suppliers;
create policy "Admins can insert any supplier"
on public.suppliers
for insert
to authenticated
with check (public.is_admin());

-- UPDATE
drop policy if exists "Suppliers can update own supplier" on public.suppliers;
create policy "Suppliers can update own supplier"
on public.suppliers
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can update any supplier" on public.suppliers;
create policy "Admins can update any supplier"
on public.suppliers
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE (admin only)
drop policy if exists "Admins can delete any supplier" on public.suppliers;
create policy "Admins can delete any supplier"
on public.suppliers
for delete
to authenticated
using (public.is_admin());
