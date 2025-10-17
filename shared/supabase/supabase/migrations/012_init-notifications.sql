-- Notifications + RLS

-- Enum for notification type
do $$
begin
  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum ('order_update', 'promotion', 'safety_alert');
  end if;
end$$;

create table if not exists public.notifications (
  notification_id text primary key,                                         -- doc ID
  user_id text not null references public.users(user_id) on delete cascade,  -- recipient
  title text not null,
  body text not null,
  type public.notification_type not null,
  is_read boolean not null default false,
  related_order_id text references public.orders(order_id) on delete set null,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);
create index if not exists idx_notifications_type on public.notifications(type);
create index if not exists idx_notifications_created_at on public.notifications(created_at);

comment on table public.notifications is 'User notifications (order updates, promotions, safety alerts).';

-- Trigger to restrict non-admin updates to marking as read
create or replace function public.prevent_notification_mutation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if tg_op = 'UPDATE' and not public.is_admin() then
    if new.user_id is distinct from old.user_id then
      raise exception 'Not allowed to change user_id';
    end if;
    if new.title is distinct from old.title
       or new.body is distinct from old.body
       or new.type is distinct from old.type
       or coalesce(new.related_order_id, '') is distinct from coalesce(old.related_order_id, '')
       or new.created_at is distinct from old.created_at then
      raise exception 'Only is_read can be changed by non-admins';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_notifications_no_escalation on public.notifications;
create trigger trg_notifications_no_escalation
before update on public.notifications
for each row execute function public.prevent_notification_mutation();

-- RLS
alter table public.notifications enable row level security;

-- Read: users can read their own notifications
drop policy if exists "Users can read own notifications" on public.notifications;
create policy "Users can read own notifications"
on public.notifications
for select
to authenticated
using (user_id = public.jwt_uid_text());

-- Read: admins can read all
drop policy if exists "Admins can read all notifications" on public.notifications;
create policy "Admins can read all notifications"
on public.notifications
for select
to authenticated
using (public.is_admin());

-- Insert: admins or users (must target themselves)
drop policy if exists "Admins can insert notifications" on public.notifications;
create policy "Admins can insert notifications"
on public.notifications
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Users can insert own notifications" on public.notifications;
create policy "Users can insert own notifications"
on public.notifications
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

-- Update: users can update (mark read) on their rows; admins can update any
drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications"
on public.notifications
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can update any notification" on public.notifications;
create policy "Admins can update any notification"
on public.notifications
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete notifications" on public.notifications;
create policy "Admins can delete notifications"
on public.notifications
for delete
to authenticated
using (public.is_admin());