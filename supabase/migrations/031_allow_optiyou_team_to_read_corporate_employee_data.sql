-- Let OptiYou team members inspect employee imports and scan sessions for
-- corporate scanner operations. Corporate users keep their existing owner-only
-- access; this only adds read access for the operations team.

drop policy if exists "OptiYou team can read corporate patients"
  on public.patients;

create policy "OptiYou team can read corporate patients"
  on public.patients
  for select
  to authenticated
  using (
    public.is_optiyou_team_member()
    and created_by_user_id in (
      select up.id
      from public.user_profiles up
      join public.roles r on r.id = up.role_id
      where r.role_code = 'CORPORATE'
    )
  );

do $$
begin
  if to_regclass('public.corporate_scan_sessions') is not null then
    drop policy if exists "OptiYou team can read corporate scan sessions"
      on public.corporate_scan_sessions;

    create policy "OptiYou team can read corporate scan sessions"
      on public.corporate_scan_sessions
      for select
      to authenticated
      using (public.is_optiyou_team_member());
  end if;
end $$;
