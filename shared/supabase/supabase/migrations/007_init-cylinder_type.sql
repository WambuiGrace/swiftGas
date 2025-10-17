-- Cylinder types + RLS

-- Table:
-- - cylinder_id: PK (string)
-- - cylinder_type_id: doc ID (unique string)
-- - code: FK to gas_types.code
create table if not exists public.cylinder_types (
  cylinder_id text primary key,
  cylinder_type_id text not null unique,
  code text not null references public.gas_types(code) on update cascade on delete restrict,

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

drop trigger if exists trg_cylinder_types_set_updated_at on public.cylinder_types;
create trigger trg_cylinder_types_set_updated_at
before update on public.cylinder_types
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_cylinder_types_code on public.cylinder_types(code);

comment on table public.cylinder_types is 'Cylinder type mapping to gas types.';
comment on column public.cylinder_types.cylinder_id is 'Primary key (string).';
comment on column public.cylinder_types.cylinder_type_id is 'Doc ID (unique).';
comment on column public.cylinder_types.code is 'FK to gas_types.code';

-- RLS
alter table public.cylinder_types enable row level security;

-- Read: any authenticated user can read
drop policy if exists "Anyone authenticated can read cylinder types" on public.cylinder_types;
create policy "Anyone authenticated can read cylinder types"
on public.cylinder_types
for select
to authenticated
using (true);

-- Insert: admin only
drop policy if exists "Admins can insert cylinder types" on public.cylinder_types;
create policy "Admins can insert cylinder types"
on public.cylinder_types
for insert
to authenticated
with check (public.is_admin());

-- Update: admin only
drop policy if exists "Admins can update cylinder types" on public.cylinder_types;
create policy "Admins can update cylinder types"
on public.cylinder_types
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Delete: admin only
drop policy if exists "Admins can delete cylinder types" on public.cylinder_types;
create policy "Admins can delete cylinder types"
on public.cylinder_types
for delete
to authenticated
using (public.is_admin());