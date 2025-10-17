-- Safety tips + RLS

create table if not exists public.safety_tips (
  tip_id text primary key,                 -- doc ID
  title text not null,
  content text not null,
  category text not null,                  -- e.g. storage, installation, emergency
  icon_name text,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_safety_tips_category on public.safety_tips(category);
create index if not exists idx_safety_tips_created_at on public.safety_tips(created_at);

comment on table public.safety_tips is 'Curated safety tips for users.';
comment on column public.safety_tips.category is 'Category such as storage, installation, emergency.';

-- RLS
alter table public.safety_tips enable row level security;

-- Read: any authenticated user can read tips
drop policy if exists "Anyone authenticated can read safety tips" on public.safety_tips;
create policy "Anyone authenticated can read safety tips"
on public.safety_tips
for select
to authenticated
using (true);

-- Insert: admin only
drop policy if exists "Admins can insert safety tips" on public.safety_tips;
create policy "Admins can insert safety tips"
on public.safety_tips
for insert
to authenticated
with check (public.is_admin());

-- Update: admin only
drop policy if exists "Admins can update safety tips" on public.safety_tips;
create policy "Admins can update safety tips"
on public.safety_tips
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete safety tips" on public.safety_tips;
create policy "Admins can delete safety tips"
on public.safety_tips
for delete
to authenticated
using (public.is_admin());