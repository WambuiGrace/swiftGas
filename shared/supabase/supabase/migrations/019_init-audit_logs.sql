-- Audit logs + RLS

-- Table
create table if not exists public.audit_logs (
  log_id text primary key,                                                    -- doc ID

  user_id text references public.users(user_id) on delete set null,
  user_type public.user_type not null,                                        -- admin | supplier | driver | customer

  action text not null,                                                       -- e.g., "updated_order_status"
  entity text not null,                                                       -- e.g., "orders", "users", "inventory"
  entity_id text not null,                                                    -- target entity doc ID

  changes jsonb not null default '{}'::jsonb check (jsonb_typeof(changes) = 'object'), -- before/after payload
  ip_address text,

  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_audit_logs_user_id on public.audit_logs(user_id);
create index if not exists idx_audit_logs_entity on public.audit_logs(entity, entity_id);
create index if not exists idx_audit_logs_created_at on public.audit_logs(created_at);

comment on table public.audit_logs is 'Immutable audit trail of user actions across entities.';

-- RLS
alter table public.audit_logs enable row level security;

-- SELECT: users can read their own logs
drop policy if exists "Users can read own audit logs" on public.audit_logs;
create policy "Users can read own audit logs"
on public.audit_logs
for select
to authenticated
using (coalesce(user_id, '') = public.jwt_uid_text());

-- SELECT: admins can read all logs
drop policy if exists "Admins can read all audit logs" on public.audit_logs;
create policy "Admins can read all audit logs"
on public.audit_logs
for select
to authenticated
using (public.is_admin());

-- INSERT: users can log their own actions; admins can insert any
drop policy if exists "Users can insert own audit logs" on public.audit_logs;
create policy "Users can insert own audit logs"
on public.audit_logs
for insert
to authenticated
with check (coalesce(user_id, '') = public.jwt_uid_text());

drop policy if exists "Admins can insert any audit log" on public.audit_logs;
create policy "Admins can insert any audit log"
on public.audit_logs
for insert
to authenticated
with check (public.is_admin());

-- UPDATE: admin only (audit entries are immutable to users)
drop policy if exists "Admins can update audit logs" on public.audit_logs;
create policy "Admins can update audit logs"
on public.audit_logs
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE: admin only
drop policy if exists "Admins can delete audit logs" on public.audit_logs;
create policy "Admins can delete audit logs"
on public.audit_logs
for delete
to authenticated
using (public.is_admin());