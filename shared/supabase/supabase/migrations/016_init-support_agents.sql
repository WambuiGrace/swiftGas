-- Support agents + RLS

-- Enum for agent role
do $$
begin
  if not exists (select 1 from pg_type where typname = 'support_agent_role') then
    create type public.support_agent_role as enum ('support_agent', 'supervisor');
  end if;
end$$;

create table if not exists public.support_agents (
  agent_id text primary key,                                                  -- doc ID
  user_id text not null unique references public.users(user_id) on delete cascade,
  name text not null,
  email text,
  phone text,
  role public.support_agent_role not null default 'support_agent',
  assigned_tickets text[] not null default '{}',                              -- array of ticketIds
  is_active boolean not null default true,
  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Updated-at trigger (idempotent)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_support_agents_set_updated_at on public.support_agents;
create trigger trg_support_agents_set_updated_at
before update on public.support_agents
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_support_agents_user_id on public.support_agents(user_id);
create index if not exists idx_support_agents_role on public.support_agents(role);
create index if not exists idx_support_agents_is_active on public.support_agents(is_active);

comment on table public.support_agents is 'Support agents and supervisors linked to users.';
comment on column public.support_agents.assigned_tickets is 'Array of ticket IDs assigned to the agent.';

-- Prevent privilege escalation by non-admins
create or replace function public.prevent_support_agent_privilege_escalation()
returns trigger
language plpgsql
security definer
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if not public.is_admin() then
    if new.user_id is distinct from old.user_id then
      raise exception 'Not allowed to change user_id';
    end if;
    if new.role is distinct from old.role then
      raise exception 'Not allowed to change role';
    end if;
    if new.is_active is distinct from old.is_active then
      raise exception 'Not allowed to change is_active';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_support_agents_no_escalation on public.support_agents;
create trigger trg_support_agents_no_escalation
before update on public.support_agents
for each row execute function public.prevent_support_agent_privilege_escalation();

-- RLS
alter table public.support_agents enable row level security;

-- SELECT
drop policy if exists "Agents can read self" on public.support_agents;
create policy "Agents can read self"
on public.support_agents
for select
to authenticated
using (user_id = public.jwt_uid_text());

drop policy if exists "Admins can read all agents" on public.support_agents;
create policy "Admins can read all agents"
on public.support_agents
for select
to authenticated
using (public.is_admin());

-- INSERT
drop policy if exists "Agents can insert self" on public.support_agents;
create policy "Agents can insert self"
on public.support_agents
for insert
to authenticated
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can insert any agent" on public.support_agents;
create policy "Admins can insert any agent"
on public.support_agents
for insert
to authenticated
with check (public.is_admin());

-- UPDATE
drop policy if exists "Agents can update self" on public.support_agents;
create policy "Agents can update self"
on public.support_agents
for update
to authenticated
using (user_id = public.jwt_uid_text())
with check (user_id = public.jwt_uid_text());

drop policy if exists "Admins can update any agent" on public.support_agents;
create policy "Admins can update any agent"
on public.support_agents
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- DELETE
drop policy if exists "Admins can delete any agent" on public.support_agents;
create policy "Admins can delete any agent"
on public.support_agents
for delete
to authenticated
using (public.is_admin());