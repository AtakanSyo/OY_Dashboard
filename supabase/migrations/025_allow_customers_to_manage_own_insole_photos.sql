-- Customers can list and add insole photos belonging to their own sessions.

DROP POLICY IF EXISTS "Customers can read own reference photos"
  ON public.session_reference_photos;
CREATE POLICY "Customers can read own reference photos"
  ON public.session_reference_photos
  FOR SELECT
  TO authenticated
  USING (public.is_current_customer_of_session(session_id));

DROP POLICY IF EXISTS "Customers can insert own reference photos"
  ON public.session_reference_photos;
CREATE POLICY "Customers can insert own reference photos"
  ON public.session_reference_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    photo_type = 'insole_photo'
    AND public.is_current_customer_of_session(session_id)
    AND patient_id IN (
      SELECT id FROM public.patients WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Customers can upload own session reference photos"
  ON storage.objects;
CREATE POLICY "Customers can upload own session reference photos"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'session-files'
    AND (storage.foldername(name))[1] = 'sessions'
    AND (storage.foldername(name))[2] ~ '^[0-9]+$'
    AND (storage.foldername(name))[3] = 'reference-photos'
    AND (storage.foldername(name))[4] = 'insole_photo'
    AND public.is_current_customer_of_session(
      ((storage.foldername(name))[2])::BIGINT
    )
  );

NOTIFY pgrst, 'reload schema';
