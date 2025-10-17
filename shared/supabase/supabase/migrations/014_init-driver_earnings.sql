-- Driver earnings + RLS

-- Enum for earning status
do $$
begin
  if not exists (select 1 from pg_type where typname = 'earning_status') then
    create type public.earning_status as enum ('pending', 'paid');
  end if;
end$$;

create table if not exists public.driver_earnings (
  earning_id text primary key,                                                  -- doc ID
  driver_id text not null references public.drivers(driver_id) on delete cascade,
  order_id text references public.orders(order_id) on delete set null,
  amount numeric(12,2) not null check (amount >= 0),

  status public.earning_status not null default 'pending',
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_driver_earnings_driver on public.driver_earnings(driver_id, created_at);
create index if not exists idx_driver_earnings_order on public.driver_earnings(order_id);
create index if not exists idx_driver_earnings_status on public.driver_earnings(status);

comment on table public.driver_earnings is 'Earnings per order for drivers.';

-- Trigger: restrict non-admin field changes to status/paid_at only
create or replace function public.prevent_driver_earnings_mutation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if tg_op = 'UPDATE' and not public.is_admin() then
    -- Non-admins cannot change immutable fields
    if new.driver_id is distinct from old.driver_id
       or new.order_id is distinct from old.order_id
       or new.amount   is distinct from old.amount
       or new.created_at is distinct from old.created_at then
      raise exception 'Only status and paid_at can be changed by non-admins';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_driver_earnings_no_escalation on public.driver_earnings;
create trigger trg_driver_earnings_no_escalation
before update on public.driver_earnings
for each row execute function public.prevent_driver_earnings_mutation();

-- RLS
alter table public.driver_earnings enable row level security;

-- SELECT
drop policy if exists "Drivers can read their own earnings" on public.driver_earnings;
create policy "Drivers can read their own earnings"
on public.driver_earnings
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.driver_id = public.driver_earnings.driver_id
      and d.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Suppliers can read earnings for their drivers" on public.driver_earnings;
create policy "Suppliers can read earnings for their drivers"
on public.driver_earnings
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    join public.suppliers s on s.supplier_id = d.supplier_id
    where d.driver_id = public.driver_earnings.driver_id
      and s.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Admins can read all driver earnings" on public.driver_earnings;
create policy "Admins can read all driver earnings"
on public.driver_earnings
for select
to authenticated
using (public.is_admin());

-- INSERT
drop policy if exists "Admins can insert driver earnings" on public.driver_earnings;
create policy "Admins can insert driver earnings"
on public.driver_earnings
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Suppliers can insert earnings for their drivers" on public.driver_earnings;
create policy "Suppliers can insert earnings for their drivers"
on public.driver_earnings
for insert
to authenticated
with check (
  exists (
    select 1
    from public.drivers d
    join public.suppliers s on s.supplier_id = d.supplier_id
    where d.driver_id = public.driver_earnings.driver_id
      and s.user_id = public.jwt_uid_text()
  )
);

-- UPDATE
drop policy if exists "Admins can update any driver earning" on public.driver_earnings;
create policy "Admins can update any driver earning"
on public.driver_earnings
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Suppliers can update earnings for their drivers" on public.driver_earnings;
create policy "Suppliers can update earnings for their drivers"
on public.driver_earnings
for update
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    join public.suppliers s on s.supplier_id = d.supplier_id
    where d.driver_id = public.driver_earnings.driver_id
      and s.user_id = public.jwt_uid_text()
  )
)
with check (
  exists (
    select 1
    from public.drivers d
    join public.suppliers s on s.supplier_id = d.supplier_id
    where d.driver_id = public.driver_earnings.driver_id
      and s.user_id = public.jwt_uid_text()
  )
);

-- DELETE
drop policy if exists "Admins can delete driver earnings" on public.driver_earnings;
create policy "Admins can delete driver earnings"
on public.driver_earnings
for delete
to authenticated
using (public.is_admin());