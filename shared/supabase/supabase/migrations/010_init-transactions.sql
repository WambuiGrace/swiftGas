-- Transactions (loyalty points movements) + RLS

-- Enum for transaction type
do $$
begin
  if not exists (select 1 from pg_type where typname = 'transaction_type') then
    create type public.transaction_type as enum ('earned', 'redeemed');
  end if;
end$$;

create table if not exists public.transactions (
  transaction_id text primary key,                                         -- doc ID
  user_id text not null references public.users(user_id) on delete cascade,
  order_id text references public.orders(order_id) on delete set null,
  points_change integer not null,                                          -- +/- delta
  type public.transaction_type not null,                                   -- earned | redeemed
  description text,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_transactions_user_id on public.transactions(user_id);
create index if not exists idx_transactions_order_id on public.transactions(order_id);
create index if not exists idx_transactions_type on public.transactions(type);
create index if not exists idx_transactions_created_at on public.transactions(created_at);

comment on table public.transactions is 'Points ledger for users (earned/redeemed).';

-- RLS
alter table public.transactions enable row level security;

-- Read: users can read their own transactions
drop policy if exists "Users can read own transactions" on public.transactions;
create policy "Users can read own transactions"
on public.transactions
for select
to authenticated
using (user_id = public.jwt_uid_text());

-- Read: admins can read all
drop policy if exists "Admins can read all transactions" on public.transactions;
create policy "Admins can read all transactions"
on public.transactions
for select
to authenticated
using (public.is_admin());

-- Insert: users can insert their own rows (or Admin any)
drop policy if exists "Users can insert own transactions" on public.transactions;
create policy "Users can insert own transactions"
on public.transactions
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can insert any transaction" on public.transactions;
create policy "Admins can insert any transaction"
on public.transactions
for insert
to authenticated
with check (public.is_admin());

-- Update: admin only (ledger entries are immutable to users)
drop policy if exists "Admins can update any transaction" on public.transactions;
create policy "Admins can update any transaction"
on public.transactions
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete any transaction" on public.transactions;
create policy "Admins can delete any transaction"
on public.transactions
for delete
to authenticated
using (public.is_admin());