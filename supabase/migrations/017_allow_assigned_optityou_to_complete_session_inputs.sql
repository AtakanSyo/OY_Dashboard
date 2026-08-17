-- Allows only the OptiYou user assigned to a measurement session to inspect
-- and complete its inputs. The original expert remains the data owner.

CREATE OR REPLACE FUNCTION public.is_current_user_assigned_to_session(
  p_session_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    JOIN public.user_profiles up
      ON up.id = ms.assigned_optityou_user_id
    WHERE ms.id = p_session_id
      AND up.auth_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.can_current_user_write_session_input(
  p_session_id BIGINT,
  p_expert_user_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    JOIN public.user_profiles up
      ON up.id = ms.assigned_optityou_user_id
    WHERE ms.id = p_session_id
      AND ms.expert_user_id = p_expert_user_id
      AND up.auth_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_current_user_assigned_to_patient(
  p_patient_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    JOIN public.user_profiles up
      ON up.id = ms.assigned_optityou_user_id
    WHERE ms.patient_id = p_patient_id
      AND up.auth_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  TO authenticated;

CREATE POLICY "Assigned OptiYou can read session patients"
  ON public.patients
  FOR SELECT
  USING (public.is_current_user_assigned_to_patient(id));

CREATE POLICY "Assigned OptiYou can read anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read scan reports"
  ON public.session_scan_reports
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert scan reports"
  ON public.session_scan_reports
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update scan reports"
  ON public.session_scan_reports
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read scan files"
  ON public.session_scan_files
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert scan files"
  ON public.session_scan_files
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update scan files"
  ON public.session_scan_files
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read pressure recordings"
  ON public.session_pressure_recordings
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert pressure recordings"
  ON public.session_pressure_recordings
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update pressure recordings"
  ON public.session_pressure_recordings
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read reference photos"
  ON public.session_reference_photos
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert reference photos"
  ON public.session_reference_photos
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update reference photos"
  ON public.session_reference_photos
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read orthotic forms"
  ON public.orthotic_design_forms
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert orthotic forms"
  ON public.orthotic_design_forms
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update orthotic forms"
  ON public.orthotic_design_forms
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read analysis results"
  ON public.analysis_results
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert analysis results"
  ON public.analysis_results
  FOR INSERT
  WITH CHECK (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can update analysis results"
  ON public.analysis_results
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can read patient invites"
  ON public.patient_invites
  FOR SELECT
  USING (public.is_current_user_assigned_to_session(session_id));

CREATE POLICY "Assigned OptiYou can insert patient invites"
  ON public.patient_invites
  FOR INSERT
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can update patient invites"
  ON public.patient_invites
  FOR UPDATE
  USING (public.is_current_user_assigned_to_session(session_id))
  WITH CHECK (
    public.is_current_user_assigned_to_session(session_id)
    AND public.can_current_user_write_session_input(session_id, expert_user_id)
  );

CREATE POLICY "Assigned OptiYou can read session storage"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND public.is_current_user_assigned_to_session(
      CASE
        WHEN (storage.foldername(name))[2] ~ '^[0-9]+$'
          THEN ((storage.foldername(name))[2])::BIGINT
        ELSE NULL
      END
    )
  );

CREATE POLICY "Assigned OptiYou can insert session storage"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND public.is_current_user_assigned_to_session(
      CASE
        WHEN (storage.foldername(name))[2] ~ '^[0-9]+$'
          THEN ((storage.foldername(name))[2])::BIGINT
        ELSE NULL
      END
    )
  );

CREATE POLICY "Assigned OptiYou can update session storage"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND public.is_current_user_assigned_to_session(
      CASE
        WHEN (storage.foldername(name))[2] ~ '^[0-9]+$'
          THEN ((storage.foldername(name))[2])::BIGINT
        ELSE NULL
      END
    )
  )
  WITH CHECK (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND public.is_current_user_assigned_to_session(
      CASE
        WHEN (storage.foldername(name))[2] ~ '^[0-9]+$'
          THEN ((storage.foldername(name))[2])::BIGINT
        ELSE NULL
      END
    )
  );
