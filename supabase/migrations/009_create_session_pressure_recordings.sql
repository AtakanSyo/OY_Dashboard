CREATE TABLE IF NOT EXISTS public.session_pressure_recordings (
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

  title TEXT NOT NULL,

  frame_count INTEGER NOT NULL DEFAULT 0,
  duration_ms INTEGER NOT NULL DEFAULT 0,

  max_pressure NUMERIC,
  avg_pressure NUMERIC,

  raw_frames_json JSONB,
  storage_bucket TEXT,
  storage_path TEXT,
  upload_status TEXT NOT NULL DEFAULT 'local',

  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS session_pressure_recordings_session_id_idx
  ON public.session_pressure_recordings(session_id);

CREATE INDEX IF NOT EXISTS session_pressure_recordings_patient_id_idx
  ON public.session_pressure_recordings(patient_id);

CREATE INDEX IF NOT EXISTS session_pressure_recordings_upload_status_idx
  ON public.session_pressure_recordings(upload_status);

ALTER TABLE public.session_pressure_recordings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own pressure recordings"
  ON public.session_pressure_recordings
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own pressure recordings"
  ON public.session_pressure_recordings
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own pressure recordings"
  ON public.session_pressure_recordings
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER session_pressure_recordings_updated_at
  BEFORE UPDATE ON public.session_pressure_recordings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();