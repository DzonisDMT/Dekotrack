-- DecoTrack multi-tenant foundation. Apply with: supabase db push
create extension if not exists pgcrypto;

create type public.member_role as enum ('owner','manager','foreman','employee');
create type public.asset_status as enum ('available','assigned','maintenance','missing','retired');
create type public.transfer_status as enum ('pending','accepted','rejected','cancelled');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null default 'employee',
  created_at timestamptz not null default now(),
  unique (organization_id,user_id)
);
create index memberships_user_idx on public.memberships(user_id);

create table public.employees (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  auth_user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text,
  phone text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (organization_id,email)
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  code text not null,
  name text not null,
  site_address text,
  city text,
  manager_employee_id uuid references public.employees(id) on delete set null,
  status text not null default 'active' check (status in ('active','completed','archived')),
  created_at timestamptz not null default now(),
  unique (organization_id,code)
);

create table public.tools (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  asset_tag text not null,
  name text not null,
  category text not null default 'Other',
  manufacturer text,
  model text,
  serial_number text,
  status public.asset_status not null default 'available',
  current_employee_id uuid references public.employees(id) on delete set null,
  current_project_id uuid references public.projects(id) on delete set null,
  purchase_date date,
  service_due_at date,
  notes text,
  qr_code_value text not null unique default ('DT-' || replace(gen_random_uuid()::text,'-','')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,asset_tag)
);
create index tools_org_status_idx on public.tools(organization_id,status);
create index tools_org_employee_idx on public.tools(organization_id,current_employee_id);
create index tools_org_project_idx on public.tools(organization_id,current_project_id);

create table public.tool_bags (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  bag_tag text not null,
  name text not null,
  current_employee_id uuid references public.employees(id) on delete set null,
  current_project_id uuid references public.projects(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (organization_id,bag_tag)
);

create table public.bag_items (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  bag_id uuid not null references public.tool_bags(id) on delete cascade,
  tool_id uuid not null references public.tools(id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (bag_id,tool_id),
  unique (tool_id)
);

create table public.transfers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  reference text not null,
  from_employee_id uuid references public.employees(id) on delete set null,
  to_employee_id uuid references public.employees(id) on delete set null,
  from_project_id uuid references public.projects(id) on delete set null,
  to_project_id uuid references public.projects(id) on delete set null,
  initiated_by uuid not null references auth.users(id),
  accepted_by uuid references auth.users(id),
  status public.transfer_status not null default 'accepted',
  notes text,
  transferred_at timestamptz not null default now(),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (organization_id,reference)
);

create table public.transfer_items (
  transfer_id uuid not null references public.transfers(id) on delete cascade,
  tool_id uuid not null references public.tools(id) on delete restrict,
  primary key (transfer_id,tool_id)
);

create table public.maintenance_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  tool_id uuid not null references public.tools(id) on delete cascade,
  reported_by uuid references auth.users(id),
  description text not null,
  status text not null default 'open' check (status in ('open','in_progress','completed')),
  due_at date,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_org_created_idx on public.audit_log(organization_id,created_at desc);

create or replace function public.is_org_member(target_org uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.memberships m where m.organization_id=target_org and m.user_id=auth.uid()) $$;

create or replace function public.has_org_role(target_org uuid, allowed public.member_role[])
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.memberships m where m.organization_id=target_org and m.user_id=auth.uid() and m.role=any(allowed)) $$;

alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.employees enable row level security;
alter table public.projects enable row level security;
alter table public.tools enable row level security;
alter table public.tool_bags enable row level security;
alter table public.bag_items enable row level security;
alter table public.transfers enable row level security;
alter table public.transfer_items enable row level security;
alter table public.maintenance_records enable row level security;
alter table public.audit_log enable row level security;

create policy "members read their organizations" on public.organizations for select using (public.is_org_member(id));
create policy "members read memberships" on public.memberships for select using (public.is_org_member(organization_id));
create policy "managers manage memberships" on public.memberships for all using (public.has_org_role(organization_id,array['owner','manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager']::public.member_role[]));

create policy "org members read employees" on public.employees for select using (public.is_org_member(organization_id));
create policy "managers manage employees" on public.employees for all using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));

create policy "org members read projects" on public.projects for select using (public.is_org_member(organization_id));
create policy "managers manage projects" on public.projects for all using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));

create policy "org members read tools" on public.tools for select using (public.is_org_member(organization_id));
create policy "managers manage tools" on public.tools for all using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));

create policy "org members read bags" on public.tool_bags for select using (public.is_org_member(organization_id));
create policy "managers manage bags" on public.tool_bags for all using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));
create policy "org members read bag items" on public.bag_items for select using (public.is_org_member(organization_id));
create policy "managers manage bag items" on public.bag_items for all using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));

create policy "org members read transfers" on public.transfers for select using (public.is_org_member(organization_id));
create policy "members create transfers" on public.transfers for insert with check (public.is_org_member(organization_id) and initiated_by=auth.uid());
create policy "org members read transfer items" on public.transfer_items for select using (exists(select 1 from public.transfers t where t.id=transfer_id and public.is_org_member(t.organization_id)));
create policy "org members read maintenance" on public.maintenance_records for select using (public.is_org_member(organization_id));
create policy "members report maintenance" on public.maintenance_records for insert with check (public.is_org_member(organization_id) and reported_by=auth.uid());
create policy "managers update maintenance" on public.maintenance_records for update using (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','manager','foreman']::public.member_role[]));
create policy "org members read audit" on public.audit_log for select using (public.is_org_member(organization_id));

-- One transaction for every handover: validate org membership, update current custody and write history.
create or replace function public.complete_tool_transfer(
  p_organization_id uuid,
  p_tool_ids uuid[],
  p_to_employee_id uuid,
  p_to_project_id uuid,
  p_notes text default null
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare
  v_transfer_id uuid;
  v_reference text;
  v_from_employee uuid;
  v_from_project uuid;
  v_tool_id uuid;
begin
  if auth.uid() is null or not public.is_org_member(p_organization_id) then
    raise exception 'Not authorized for this organization';
  end if;
  if cardinality(p_tool_ids) is null or cardinality(p_tool_ids)=0 then
    raise exception 'Select at least one tool';
  end if;
  if p_to_employee_id is null and p_to_project_id is null then
    raise exception 'A recipient employee or project is required';
  end if;
  select current_employee_id,current_project_id into v_from_employee,v_from_project
    from public.tools where id=p_tool_ids[1] and organization_id=p_organization_id for update;
  if not found then raise exception 'Tool not found in organization'; end if;

  foreach v_tool_id in array p_tool_ids loop
    perform 1 from public.tools where id=v_tool_id and organization_id=p_organization_id for update;
    if not found then raise exception 'One or more tools are outside this organization'; end if;
  end loop;

  v_reference := 'TR-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.transfers(organization_id,reference,from_employee_id,to_employee_id,from_project_id,to_project_id,initiated_by,accepted_by,status,notes,accepted_at)
  values(p_organization_id,v_reference,v_from_employee,p_to_employee_id,v_from_project,p_to_project_id,auth.uid(),auth.uid(),'accepted',p_notes,now())
  returning id into v_transfer_id;

  insert into public.transfer_items(transfer_id,tool_id) select v_transfer_id,unnest(p_tool_ids);
  update public.tools set current_employee_id=p_to_employee_id,current_project_id=p_to_project_id,status='assigned',updated_at=now()
    where id=any(p_tool_ids) and organization_id=p_organization_id;
  insert into public.audit_log(organization_id,actor_user_id,entity_type,entity_id,action,details)
  values(p_organization_id,auth.uid(),'transfer',v_transfer_id,'tool_transfer_completed',
    jsonb_build_object('tool_ids',p_tool_ids,'to_employee_id',p_to_employee_id,'to_project_id',p_to_project_id));
  return v_transfer_id;
end;
$$;
revoke all on function public.complete_tool_transfer(uuid,uuid[],uuid,uuid,text) from public;
grant execute on function public.complete_tool_transfer(uuid,uuid[],uuid,uuid,text) to authenticated;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create trigger tools_updated_at before update on public.tools for each row execute function public.set_updated_at();
