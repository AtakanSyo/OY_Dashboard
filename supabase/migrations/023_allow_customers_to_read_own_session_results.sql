-- Lets a signed-in customer read only the result data and private files that
-- belong to a measurement session linked to their own patient record.

CREATE OR REPLACE FUNCTION public.is_current_customer_of_session(
  p_session_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    JOIN public.patients p
      ON p.id = ms.patient_id
    WHERE ms.id = p_session_id
      AND p.auth_user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_customer_of_session(BIGINT)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_current_customer_of_session(BIGINT)
  TO authenticated;

DROP POLICY IF EXISTS "Customers can read own scan reports"
  ON public.session_scan_reports;
CREATE POLICY "Customers can read own scan reports"
  ON public.session_scan_reports
  FOR SELECT
  TO authenticated
  USING (public.is_current_customer_of_session(session_id));

DROP POLICY IF EXISTS "Customers can read own scan files"
  ON public.session_scan_files;
CREATE POLICY "Customers can read own scan files"
  ON public.session_scan_files
  FOR SELECT
  TO authenticated
  USING (public.is_current_customer_of_session(session_id));

DROP POLICY IF EXISTS "Customers can read own pressure recordings"
  ON public.session_pressure_recordings;
CREATE POLICY "Customers can read own pressure recordings"
  ON public.session_pressure_recordings
  FOR SELECT
  TO authenticated
  USING (public.is_current_customer_of_session(session_id));

DROP POLICY IF EXISTS "Customers can read own session result storage"
  ON storage.objects;
CREATE POLICY "Customers can read own session result storage"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND public.is_current_customer_of_session(
      CASE
        WHEN (storage.foldername(name))[2] ~ '^[0-9]+$'
          THEN ((storage.foldername(name))[2])::BIGINT
        ELSE NULL
      END
    )
  );

NOTIFY pgrst, 'reload schema';
