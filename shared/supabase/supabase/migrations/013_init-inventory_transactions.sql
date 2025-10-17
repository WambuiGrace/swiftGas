-- Inventory transactions + RLS

-- Enum for inventory transaction type
do $$
begin
  if not exists (select 1 from pg_type where typname = 'inventory_tx_type') then
    create type public.inventory_tx_type as enum ('restock', 'sale', 'adjustment');
  end if;
end$$;

create table if not exists public.inventory_transactions (
  transaction_id text primary key,                                           -- doc ID

  supplier_id text not null references public.suppliers(supplier_id) on delete cascade,
  cylinder_id text references public.cylinder_types(cylinder_id) on delete set null, -- optional FK
  size text not null,

  type public.inventory_tx_type not null,                                    -- restock | sale | adjustment
  quantity_change integer not null,                                          -- +/- delta
  previous_quantity integer not null default 0,
  new_quantity integer not null default 0,

  order_id text references public.orders(order_id) on delete set null,       -- for sales
  notes text,

  created_by text not null references public.users(user_id) on delete restrict,
  created_at timestamptz not null default now(),

  -- Ensure arithmetic consistency
  constraint inventory_tx_qty_consistency check (new_quantity = previous_quantity + quantity_change)
);

-- Indexes
create index if not exists idx_inventory_tx_supplier on public.inventory_transactions(supplier_id, created_at);
create index if not exists idx_inventory_tx_cylinder on public.inventory_transactions(cylinder_id);
create index if not exists idx_inventory_tx_type on public.inventory_transactions(type);
create index if not exists idx_inventory_tx_order on public.inventory_transactions(order_id);
create index if not exists idx_inventory_tx_created_by on public.inventory_transactions(created_by);

comment on table public.inventory_transactions is 'Immutable audit of supplier inventory changes (restock/sale/adjustment).';

-- RLS
alter table public.inventory_transactions enable row level security;

-- SELECT
drop policy if exists "Suppliers can read their inventory transactions" on public.inventory_transactions;
create policy "Suppliers can read their inventory transactions"
on public.inventory_transactions
for select
to authenticated
using (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.inventory_transactions.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
);

drop policy if exists "Admins can read all inventory transactions" on public.inventory_transactions;
create policy "Admins can read all inventory transactions"
on public.inventory_transactions
for select
to authenticated
using (public.is_admin());

-- INSERT (suppliers for their own supplier_id, or admins). Enforce created_by is caller for suppliers.
drop policy if exists "Suppliers can insert inventory transactions for own supplier" on public.inventory_transactions;
create policy "Suppliers can insert inventory transactions for own supplier"
on public.inventory_transactions
for insert
to authenticated
with check (
  exists (
    select 1
    from public.suppliers s
    where s.supplier_id = public.inventory_transactions.supplier_id
      and s.user_id = public.jwt_uid_text()
  )
  and created_by = public.jwt_uid_text()
);

drop policy if exists "Admins can insert any inventory transaction" on public.inventory_transactions;
create policy "Admins can insert any inventory transaction"
on public.inventory_transactions
for insert
to authenticated
with check (public.is_admin());

-- UPDATE: ledger entries are immutable to non-admins
drop policy if exists "Admins can update any inventory transaction" on public.inventory_transactions;
create policy "Admins can update any inventory transaction"
on public.inventory_transactions
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE: admin only
drop policy if exists "Admins can delete inventory transactions" on public.inventory_transactions;
create policy "Admins can delete inventory transactions"
on public.inventory_transactions
for delete
to authenticated
using (public.is_admin());