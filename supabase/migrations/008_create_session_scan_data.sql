CREATE TABLE IF NOT EXISTS public.session_scan_reports (
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

  report_no TEXT,
  report_date TEXT,
  report_time TEXT,

  parsed_report_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  raw_text TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT session_scan_reports_unique_session
    UNIQUE(session_id)
);

CREATE TABLE IF NOT EXISTS public.session_scan_files (
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

  file_type TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  size_bytes BIGINT,

  local_file_path TEXT,

  storage_bucket TEXT,
  storage_path TEXT,
  public_url TEXT,
  signed_url_expires_at TIMESTAMPTZ,

  upload_status TEXT NOT NULL DEFAULT 'local',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT session_scan_files_unique_session_type
    UNIQUE(session_id, file_type)
);

CREATE INDEX IF NOT EXISTS session_scan_reports_session_id_idx
  ON public.session_scan_reports(session_id);

CREATE INDEX IF NOT EXISTS session_scan_files_session_id_idx
  ON public.session_scan_files(session_id);

CREATE INDEX IF NOT EXISTS session_scan_files_upload_status_idx
  ON public.session_scan_files(upload_status);

ALTER TABLE public.session_scan_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_scan_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own session scan reports"
  ON public.session_scan_reports
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own session scan reports"
  ON public.session_scan_reports
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own session scan reports"
  ON public.session_scan_reports
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can read own session scan files"
  ON public.session_scan_files
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own session scan files"
  ON public.session_scan_files
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own session scan files"
  ON public.session_scan_files
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER session_scan_reports_updated_at
  BEFORE UPDATE ON public.session_scan_reports
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER session_scan_files_updated_at
  BEFORE UPDATE ON public.session_scan_files
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();