-- Tracks B2B factory/corporate scanner deployments at the project level.
-- Individual employee scan records stay in corporate_scan_sessions and can be
-- attached to a project with project_id.

create table if not exists public.corporate_scan_projects (
  id uuid primary key default gen_random_uuid(),
  corporate_user_id uuid references auth.users(id) on delete set null,
  company_name text not null,
  factory_name text,
  location text,
  contact_name text,
  contact_phone text,
  contact_email text,
  device_id text,
  status text not null default 'preparing'
    check (status in ('preparing', 'active', 'paused', 'completed', 'closed')),
  starts_at date,
  ends_at date,
  target_employee_count integer not null default 0,
  notes text,
  created_by_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.corporate_scan_projects enable row level security;

create index if not exists idx_corporate_scan_projects_corporate_user
  on public.corporate_scan_projects(corporate_user_id);

create index if not exists idx_corporate_scan_projects_status
  on public.corporate_scan_projects(status);

create index if not exists idx_corporate_scan_projects_created_at
  on public.corporate_scan_projects(created_at desc);

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'corporate_scan_sessions'
      and column_name = 'id'
  ) then
    alter table public.corporate_scan_sessions
      add column if not exists project_id uuid
      references public.corporate_scan_projects(id)
      on delete set null;

    create index if not exists idx_corporate_scan_sessions_project
      on public.corporate_scan_sessions(project_id);
  end if;
end $$;

create or replace function public.set_corporate_scan_projects_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_corporate_scan_projects_updated_at
  on public.corporate_scan_projects;

create trigger set_corporate_scan_projects_updated_at
before update on public.corporate_scan_projects
for each row
execute function public.set_corporate_scan_projects_updated_at();

create or replace function public.is_optiyou_team_member()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_uid text := auth.uid()::text;
  match_found boolean := false;
begin
  if current_uid is null then
    return false;
  end if;

  if to_regclass('public.user_profiles') is not null then
    execute $q$
      select exists (
        select 1
        from public.user_profiles p
        where (
          to_jsonb(p)->>'user_id' = $1
          or to_jsonb(p)->>'id' = $1
        )
        and lower(coalesce(
          to_jsonb(p)->>'role_code',
          to_jsonb(p)->>'role',
          to_jsonb(p)->>'role_name',
          ''
        )) in ('optiyou_team', 'opti_you_team', 'optiyouteam')
      )
    $q$ using current_uid into match_found;

    if match_found then
      return true;
    end if;
  end if;

  if to_regclass('public.user_profiles_full') is not null then
    execute $q$
      select exists (
        select 1
        from public.user_profiles_full p
        where (
          to_jsonb(p)->>'user_id' = $1
          or to_jsonb(p)->>'id' = $1
        )
        and lower(coalesce(
          to_jsonb(p)->>'role_code',
          to_jsonb(p)->>'role',
          to_jsonb(p)->>'role_name',
          ''
        )) in ('optiyou_team', 'opti_you_team', 'optiyouteam')
      )
    $q$ using current_uid into match_found;
  end if;

  return coalesce(match_found, false);
exception
  when others then
    return false;
end;
$$;

drop policy if exists "Corporate scan projects readable by owners and OptiYou team"
  on public.corporate_scan_projects;

create policy "Corporate scan projects readable by owners and OptiYou team"
  on public.corporate_scan_projects
  for select
  to authenticated
  using (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or public.is_optiyou_team_member()
  );

drop policy if exists "Corporate scan projects insertable by owners and OptiYou team"
  on public.corporate_scan_projects;

create policy "Corporate scan projects insertable by owners and OptiYou team"
  on public.corporate_scan_projects
  for insert
  to authenticated
  with check (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or public.is_optiyou_team_member()
  );

drop policy if exists "Corporate scan projects updatable by owners and OptiYou team"
  on public.corporate_scan_projects;

create policy "Corporate scan projects updatable by owners and OptiYou team"
  on public.corporate_scan_projects
  for update
  to authenticated
  using (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or public.is_optiyou_team_member()
  )
  with check (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or public.is_optiyou_team_member()
  );

drop policy if exists "Corporate scan projects deletable by owners and OptiYou team"
  on public.corporate_scan_projects;

create policy "Corporate scan projects deletable by owners and OptiYou team"
  on public.corporate_scan_projects
  for delete
  to authenticated
  using (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or public.is_optiyou_team_member()
  );
