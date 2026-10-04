CREATE TABLE IF NOT EXISTS public.corporate_scan_sessions (
  id BIGSERIAL PRIMARY KEY,

  corporate_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  patient_id BIGINT REFERENCES public.patients(id) ON DELETE CASCADE,
  patient_code TEXT NOT NULL,

  scanner_device_id TEXT,
  status TEXT NOT NULL DEFAULT 'waiting',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  local_output_path TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT corporate_scan_sessions_status_check
    CHECK (status IN ('waiting', 'scanning', 'completed', 'failed', 'needs_repeat')),
  CONSTRAINT corporate_scan_sessions_user_patient_unique
    UNIQUE (corporate_user_id, patient_id)
);

CREATE INDEX IF NOT EXISTS corporate_scan_sessions_corporate_user_id_idx
  ON public.corporate_scan_sessions(corporate_user_id);

CREATE INDEX IF NOT EXISTS corporate_scan_sessions_patient_id_idx
  ON public.corporate_scan_sessions(patient_id);

CREATE INDEX IF NOT EXISTS corporate_scan_sessions_status_idx
  ON public.corporate_scan_sessions(status);

ALTER TABLE public.corporate_scan_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Corporate users can read own scan sessions"
  ON public.corporate_scan_sessions
  FOR SELECT
  USING (
    corporate_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Corporate users can insert own scan sessions"
  ON public.corporate_scan_sessions
  FOR INSERT
  WITH CHECK (
    corporate_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Corporate users can update own scan sessions"
  ON public.corporate_scan_sessions
  FOR UPDATE
  USING (
    corporate_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER corporate_scan_sessions_updated_at
  BEFORE UPDATE ON public.corporate_scan_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
