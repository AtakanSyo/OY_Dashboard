CREATE TABLE IF NOT EXISTS public.session_reference_photos (
  id BIGSERIAL PRIMARY KEY,

  session_id BIGINT NOT NULL
    REFERENCES public.measurement_sessions(id)
    ON DELETE CASCADE,

  patient_id BIGINT
    REFERENCES public.patients(id)
    ON DELETE SET NULL,

  expert_user_id BIGINT
    REFERENCES public.user_profiles(id)
    ON DELETE SET NULL,

  photo_type TEXT NOT NULL,

  file_name TEXT,
  mime_type TEXT,
  size_bytes BIGINT,

  local_file_path TEXT,

  storage_bucket TEXT,
  storage_path TEXT,
  public_url TEXT,

  upload_status TEXT NOT NULL DEFAULT 'local',

  note TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS session_reference_photos_session_id_idx
  ON public.session_reference_photos(session_id);

CREATE INDEX IF NOT EXISTS session_reference_photos_patient_id_idx
  ON public.session_reference_photos(patient_id);

ALTER TABLE public.session_reference_photos
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own reference photos"
  ON public.session_reference_photos
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own reference photos"
  ON public.session_reference_photos
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own reference photos"
  ON public.session_reference_photos
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER session_reference_photos_updated_at
  BEFORE UPDATE ON public.session_reference_photos
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();