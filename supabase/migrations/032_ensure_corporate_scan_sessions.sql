-- Required for corporate kiosk scan status to appear on the corporate
-- dashboard and employees pages after a scan is completed.

create table if not exists public.corporate_scan_sessions (
  id bigserial primary key,
  corporate_user_id bigint references public.user_profiles(id) on delete cascade,
  patient_id bigint references public.patients(id) on delete cascade,
  patient_code text not null,
  scanner_device_id text,
  status text not null default 'waiting',
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  local_output_path text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint corporate_scan_sessions_status_check
    check (status in ('waiting', 'scanning', 'completed', 'failed', 'needs_repeat')),
  constraint corporate_scan_sessions_user_patient_unique
    unique (corporate_user_id, patient_id)
);

alter table public.corporate_scan_sessions
  add column if not exists project_id uuid
  references public.corporate_scan_projects(id)
  on delete set null;

create index if not exists corporate_scan_sessions_corporate_user_id_idx
  on public.corporate_scan_sessions(corporate_user_id);

create index if not exists corporate_scan_sessions_patient_id_idx
  on public.corporate_scan_sessions(patient_id);

create index if not exists corporate_scan_sessions_status_idx
  on public.corporate_scan_sessions(status);

create index if not exists corporate_scan_sessions_project_id_idx
  on public.corporate_scan_sessions(project_id);

alter table public.corporate_scan_sessions enable row level security;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists corporate_scan_sessions_updated_at
  on public.corporate_scan_sessions;

create trigger corporate_scan_sessions_updated_at
before update on public.corporate_scan_sessions
for each row
execute function public.set_updated_at();

drop policy if exists "Corporate users can read own scan sessions"
  on public.corporate_scan_sessions;

create policy "Corporate users can read own scan sessions"
  on public.corporate_scan_sessions
  for select
  to authenticated
  using (
    corporate_user_id in (
      select id from public.user_profiles
      where auth_id = auth.uid()
    )
  );

drop policy if exists "Corporate users can insert own scan sessions"
  on public.corporate_scan_sessions;

create policy "Corporate users can insert own scan sessions"
  on public.corporate_scan_sessions
  for insert
  to authenticated
  with check (
    corporate_user_id in (
      select id from public.user_profiles
      where auth_id = auth.uid()
    )
  );

drop policy if exists "Corporate users can update own scan sessions"
  on public.corporate_scan_sessions;

create policy "Corporate users can update own scan sessions"
  on public.corporate_scan_sessions
  for update
  to authenticated
  using (
    corporate_user_id in (
      select id from public.user_profiles
      where auth_id = auth.uid()
    )
  )
  with check (
    corporate_user_id in (
      select id from public.user_profiles
      where auth_id = auth.uid()
    )
  );

drop policy if exists "OptiYou team can read corporate scan sessions"
  on public.corporate_scan_sessions;

create policy "OptiYou team can read corporate scan sessions"
  on public.corporate_scan_sessions
  for select
  to authenticated
  using (public.is_optiyou_team_member());
