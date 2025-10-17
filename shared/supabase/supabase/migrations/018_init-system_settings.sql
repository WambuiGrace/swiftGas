-- System settings + RLS

create table if not exists public.system_settings (
  setting_id text primary key,                                -- doc ID
  key text not null unique,                                   -- e.g. 'base_delivery_fee'
  value jsonb not null,                                       -- arbitrary JSON value
  description text,
  updated_by text not null references public.users(user_id) on delete restrict,
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_system_settings_set_updated_at on public.system_settings;
create trigger trg_system_settings_set_updated_at
before update on public.system_settings
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_system_settings_updated_at on public.system_settings(updated_at);

comment on table public.system_settings is 'Global system configuration key-value settings.';

-- RLS
alter table public.system_settings enable row level security;

-- Read: any authenticated user can read settings
drop policy if exists "Anyone authenticated can read system settings" on public.system_settings;
create policy "Anyone authenticated can read system settings"
on public.system_settings
for select
to authenticated
using (true);

-- Insert: admin only; enforce updated_by is caller
drop policy if exists "Admins can insert system settings" on public.system_settings;
create policy "Admins can insert system settings"
on public.system_settings
for insert
to authenticated
with check (public.is_admin() and updated_by = public.jwt_uid_text());

-- Update: admin only; enforce updated_by is caller
drop policy if exists "Admins can update system settings" on public.system_settings;
create policy "Admins can update system settings"
on public.system_settings
for update
to authenticated
using (public.is_admin())
with check (public.is_admin() and updated_by = public.jwt_uid_text());

-- Delete: admin only
drop policy if exists "Admins can delete system settings" on public.system_settings;
create policy "Admins can delete system settings"
on public.system_settings
for delete
to authenticated
using (public.is_admin());