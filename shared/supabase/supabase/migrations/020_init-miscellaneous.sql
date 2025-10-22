-- Miscellaneous table + RLS
-- This table stores additional flexible data related to system settings and configurations

-- Enum for miscellaneous item types
do $$
begin
  if not exists (select 1 from pg_type where typname = 'misc_item_type') then
    create type public.misc_item_type as enum (
      'promotional_banner',
      'system_announcement', 
      'maintenance_notice',
      'feature_flag',
      'external_integration',
      'metadata',
      'cache_entry'
    );
  end if;
end$$;

-- Miscellaneous table
create table if not exists public.miscellaneous (
  misc_id text primary key,                                                    -- doc ID
  
  -- Categorization
  item_type public.misc_item_type not null,
  category text not null,                                                      -- grouping category
  key text not null,                                                           -- unique key within category
  
  -- Data
  title text,
  description text,
  value jsonb not null default '{}'::jsonb check (jsonb_typeof(value) = 'object'),
  
  -- Metadata
  is_active boolean not null default true,
  priority integer not null default 0,                                         -- for ordering
  
  -- Relations
  related_setting_id text references public.system_settings(setting_id) on delete set null,
  
  -- Display configuration
  display_config jsonb default '{}'::jsonb check (jsonb_typeof(display_config) = 'object'),
  
  -- Validity period
  valid_from timestamptz,
  valid_until timestamptz,
  
  -- Audit
  created_by text not null references public.users(user_id) on delete restrict,
  updated_by text not null references public.users(user_id) on delete restrict,
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  -- Constraints
  constraint unique_category_key unique (category, key)
);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_miscellaneous_set_updated_at on public.miscellaneous;
create trigger trg_miscellaneous_set_updated_at
before update on public.miscellaneous
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_miscellaneous_item_type on public.miscellaneous(item_type);
create index if not exists idx_miscellaneous_category on public.miscellaneous(category);
create index if not exists idx_miscellaneous_key on public.miscellaneous(key);
create index if not exists idx_miscellaneous_is_active on public.miscellaneous(is_active);
create index if not exists idx_miscellaneous_priority on public.miscellaneous(priority desc);
create index if not exists idx_miscellaneous_related_setting on public.miscellaneous(related_setting_id);
create index if not exists idx_miscellaneous_valid_dates on public.miscellaneous(valid_from, valid_until);
create index if not exists idx_miscellaneous_created_at on public.miscellaneous(created_at desc);

comment on table public.miscellaneous is 'Flexible storage for promotional banners, announcements, feature flags, and other miscellaneous system data.';
comment on column public.miscellaneous.item_type is 'Type of miscellaneous item (banner, announcement, flag, etc.).';
comment on column public.miscellaneous.category is 'Grouping category for organizing items.';
comment on column public.miscellaneous.key is 'Unique identifier within a category.';
comment on column public.miscellaneous.value is 'JSONB payload with flexible structure.';
comment on column public.miscellaneous.display_config is 'JSONB configuration for UI display (colors, icons, positioning, etc.).';
comment on column public.miscellaneous.related_setting_id is 'Optional link to system_settings for configuration dependencies.';
comment on column public.miscellaneous.priority is 'Higher values appear first in ordered lists.';

-- Trigger to prevent non-admins from changing restricted fields
create or replace function public.prevent_miscellaneous_privilege_escalation()
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
    if tg_op = 'UPDATE' then
      -- Non-admins cannot change ownership or related settings
      if new.created_by is distinct from old.created_by then
        raise exception 'Not allowed to change created_by';
      end if;
      if new.related_setting_id is distinct from old.related_setting_id then
        raise exception 'Not allowed to change related_setting_id';
      end if;
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_miscellaneous_no_escalation on public.miscellaneous;
create trigger trg_miscellaneous_no_escalation
before update on public.miscellaneous
for each row execute function public.prevent_miscellaneous_privilege_escalation();

-- RLS
alter table public.miscellaneous enable row level security;

-- SELECT: Anyone authenticated can read active items within valid date range
drop policy if exists "Anyone authenticated can read active miscellaneous" on public.miscellaneous;
create policy "Anyone authenticated can read active miscellaneous"
on public.miscellaneous
for select
to authenticated
using (
  is_active = true
  and (valid_from is null or valid_from <= now())
  and (valid_until is null or valid_until >= now())
);

-- SELECT: Admins can read all items
drop policy if exists "Admins can read all miscellaneous" on public.miscellaneous;
create policy "Admins can read all miscellaneous"
on public.miscellaneous
for select
to authenticated
using (public.is_admin());

-- INSERT: Only admins can insert; enforce created_by and updated_by are caller
drop policy if exists "Admins can insert miscellaneous" on public.miscellaneous;
create policy "Admins can insert miscellaneous"
on public.miscellaneous
for insert
to authenticated
with check (
  public.is_admin() 
  and created_by = public.jwt_uid_text() 
  and updated_by = public.jwt_uid_text()
);

-- UPDATE: Admins can update all; content creators can update their own
drop policy if exists "Admins can update any miscellaneous" on public.miscellaneous;
create policy "Admins can update any miscellaneous"
on public.miscellaneous
for update
to authenticated
using (public.is_admin())
with check (public.is_admin() and updated_by = public.jwt_uid_text());

drop policy if exists "Creators can update own miscellaneous" on public.miscellaneous;
create policy "Creators can update own miscellaneous"
on public.miscellaneous
for update
to authenticated
using (created_by = public.jwt_uid_text())
with check (created_by = public.jwt_uid_text() and updated_by = public.jwt_uid_text());

-- DELETE: Only admins can delete
drop policy if exists "Admins can delete miscellaneous" on public.miscellaneous;
create policy "Admins can delete miscellaneous"
on public.miscellaneous
for delete
to authenticated
using (public.is_admin());