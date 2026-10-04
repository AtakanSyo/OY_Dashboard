-- Automatically create one corporate scan project card for every corporate
-- user profile. This keeps the OptiYou operations dashboard in sync even when
-- the corporate account is created from a different entry point.

insert into public.roles (role_code, role_name)
values ('CORPORATE', 'Kurumsal')
on conflict (role_code) do nothing;

alter table public.corporate_scan_projects
  add column if not exists corporate_profile_id bigint
  references public.user_profiles(id)
  on delete cascade;

create unique index if not exists corporate_scan_projects_profile_unique_idx
  on public.corporate_scan_projects(corporate_profile_id)
  where corporate_profile_id is not null;

create index if not exists corporate_scan_projects_profile_idx
  on public.corporate_scan_projects(corporate_profile_id);

create or replace function public.is_optiyou_team_member()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_profiles up
    join public.roles r on r.id = up.role_id
    where up.auth_id = auth.uid()
      and r.role_code = 'OPTIYOU_TEAM'
      and coalesce(up.is_active, true) = true
  );
$$;

create or replace function public.ensure_corporate_scan_project_for_profile(
  profile_id bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  profile record;
  default_company_name text;
begin
  select
    up.id,
    up.auth_id,
    up.first_name,
    up.last_name,
    up.phone,
    up.clinic_id,
    au.email,
    r.role_code,
    c.clinic_name,
    c.clinic_type
  into profile
  from public.user_profiles up
  join public.roles r on r.id = up.role_id
  join auth.users au on au.id = up.auth_id
  left join public.clinics c on c.id = up.clinic_id
  where up.id = profile_id
  limit 1;

  if profile.id is null or profile.role_code <> 'CORPORATE' then
    return;
  end if;

  default_company_name := nullif(trim(coalesce(profile.clinic_name, '')), '');

  if default_company_name is null then
    default_company_name := nullif(
      trim(concat_ws(' ', profile.first_name, profile.last_name)),
      ''
    );
  end if;

  if default_company_name is null then
    default_company_name := nullif(trim(coalesce(profile.email, '')), '');
  end if;

  insert into public.corporate_scan_projects (
    corporate_user_id,
    corporate_profile_id,
    company_name,
    factory_name,
    contact_name,
    contact_phone,
    contact_email,
    status,
    target_employee_count,
    created_by_user_id
  )
  values (
    profile.auth_id,
    profile.id,
    coalesce(default_company_name, 'Kurumsal Firma'),
    case
      when nullif(trim(coalesce(profile.clinic_name, '')), '') is null
        then null
      else profile.clinic_name
    end,
    nullif(trim(concat_ws(' ', profile.first_name, profile.last_name)), ''),
    profile.phone,
    profile.email,
    'preparing',
    0,
    profile.auth_id
  )
  on conflict (corporate_profile_id)
  where corporate_profile_id is not null
  do update set
    corporate_user_id = excluded.corporate_user_id,
    contact_name = coalesce(
      nullif(public.corporate_scan_projects.contact_name, ''),
      excluded.contact_name
    ),
    contact_phone = coalesce(
      nullif(public.corporate_scan_projects.contact_phone, ''),
      excluded.contact_phone
    ),
    contact_email = coalesce(
      nullif(public.corporate_scan_projects.contact_email, ''),
      excluded.contact_email
    );
end;
$$;

create or replace function public.handle_corporate_scan_project_profile_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ensure_corporate_scan_project_for_profile(new.id);
  return new;
end;
$$;

drop trigger if exists user_profiles_corporate_scan_project_sync
  on public.user_profiles;

create trigger user_profiles_corporate_scan_project_sync
after insert or update of role_id, clinic_id, first_name, last_name, phone
on public.user_profiles
for each row
execute function public.handle_corporate_scan_project_profile_change();

select public.ensure_corporate_scan_project_for_profile(up.id)
from public.user_profiles up
join public.roles r on r.id = up.role_id
where r.role_code = 'CORPORATE';

drop policy if exists "Corporate scan projects readable by owners and OptiYou team"
  on public.corporate_scan_projects;

create policy "Corporate scan projects readable by owners and OptiYou team"
  on public.corporate_scan_projects
  for select
  to authenticated
  using (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or exists (
      select 1
      from public.user_profiles up
      where up.id = corporate_profile_id
        and up.auth_id = auth.uid()
    )
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
    or exists (
      select 1
      from public.user_profiles up
      where up.id = corporate_profile_id
        and up.auth_id = auth.uid()
    )
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
    or exists (
      select 1
      from public.user_profiles up
      where up.id = corporate_profile_id
        and up.auth_id = auth.uid()
    )
    or public.is_optiyou_team_member()
  )
  with check (
    auth.uid() = corporate_user_id
    or auth.uid() = created_by_user_id
    or exists (
      select 1
      from public.user_profiles up
      where up.id = corporate_profile_id
        and up.auth_id = auth.uid()
    )
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
    or exists (
      select 1
      from public.user_profiles up
      where up.id = corporate_profile_id
        and up.auth_id = auth.uid()
    )
    or public.is_optiyou_team_member()
  );
