-- Customer Support Tickets + RLS

-- Enums
do $$
begin
  if not exists (select 1 from pg_type where typname = 'support_category') then
    create type public.support_category as enum (
      'delivery_issue', 'payment_issue', 'safety_concern', 'general_query', 'feedback'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'support_priority') then
    create type public.support_priority as enum ('low', 'medium', 'high');
  end if;

  if not exists (select 1 from pg_type where typname = 'support_status') then
    create type public.support_status as enum ('open', 'in_progress', 'resolved', 'closed');
  end if;
end$$;

-- Table
create table if not exists public.customer_support_tickets (
  ticket_id text primary key,                                                       -- doc ID

  user_id text not null references public.users(user_id) on delete cascade,         -- creator
  order_id text references public.orders(order_id) on delete set null,              -- optional

  category public.support_category not null,
  subject text not null,
  message text not null,
  attachments text[] not null default '{}',                                         -- array of URLs

  priority public.support_priority not null default 'medium',
  status public.support_status not null default 'open',

  assigned_to text,                                                                 -- support_agent_id (optional)
  resolution_notes text,
  feedback_rating numeric(2,1) check (feedback_rating is null or (feedback_rating >= 1 and feedback_rating <= 5)),

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

drop trigger if exists trg_customer_support_set_updated_at on public.customer_support_tickets;
create trigger trg_customer_support_set_updated_at
before update on public.customer_support_tickets
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_cst_user_id on public.customer_support_tickets(user_id);
create index if not exists idx_cst_order_id on public.customer_support_tickets(order_id);
create index if not exists idx_cst_status on public.customer_support_tickets(status);
create index if not exists idx_cst_priority on public.customer_support_tickets(priority);
create index if not exists idx_cst_created_at on public.customer_support_tickets(created_at);

comment on table public.customer_support_tickets is 'Customer support tickets and lifecycle.';
comment on column public.customer_support_tickets.assigned_to is 'Support agent identifier (optional).';

-- Prevent non-admins from changing restricted fields
create or replace function public.prevent_cst_privilege_escalation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  -- Only enforce for non-admins
  if not public.is_admin() then
    -- Owners can edit message, attachments, feedback_rating only
    if new.user_id is distinct from old.user_id then
      raise exception 'Not allowed to change user_id';
    end if;
    if new.order_id is distinct from old.order_id
       or new.category is distinct from old.category
       or new.subject is distinct from old.subject
       or new.priority is distinct from old.priority
       or new.status is distinct from old.status
       or coalesce(new.assigned_to,'') is distinct from coalesce(old.assigned_to,'')
       or coalesce(new.resolution_notes,'') is distinct from coalesce(old.resolution_notes,'') then
      raise exception 'Only message, attachments, and feedback_rating can be changed by non-admins';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_customer_support_no_escalation on public.customer_support_tickets;
create trigger trg_customer_support_no_escalation
before update on public.customer_support_tickets
for each row execute function public.prevent_cst_privilege_escalation();

-- RLS
alter table public.customer_support_tickets enable row level security;

-- SELECT
drop policy if exists "Users can read own tickets" on public.customer_support_tickets;
create policy "Users can read own tickets"
on public.customer_support_tickets
for select
to authenticated
using (user_id = public.jwt_uid_text());

drop policy if exists "Admins can read all tickets" on public.customer_support_tickets;
create policy "Admins can read all tickets"
on public.customer_support_tickets
for select
to authenticated
using (public.is_admin());

-- INSERT
drop policy if exists "Users can insert own tickets" on public.customer_support_tickets;
create policy "Users can insert own tickets"
on public.customer_support_tickets
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can insert any ticket" on public.customer_support_tickets;
create policy "Admins can insert any ticket"
on public.customer_support_tickets
for insert
to authenticated
with check (public.is_admin());

-- UPDATE
drop policy if exists "Users can update own tickets (limited fields)" on public.customer_support_tickets;
create policy "Users can update own tickets (limited fields)"
on public.customer_support_tickets
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can update any ticket" on public.customer_support_tickets;
create policy "Admins can update any ticket"
on public.customer_support_tickets
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE
drop policy if exists "Admins can delete tickets" on public.customer_support_tickets;
create policy "Admins can delete tickets"
on public.customer_support_tickets
for delete
to authenticated
using (public.is_admin());