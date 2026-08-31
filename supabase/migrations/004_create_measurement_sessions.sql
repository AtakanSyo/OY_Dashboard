CREATE TABLE IF NOT EXISTS public.measurement_sessions (
  id BIGSERIAL PRIMARY KEY,

  patient_id BIGINT REFERENCES public.patients(id) ON DELETE CASCADE,
  expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  assigned_optityou_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  clinic_id BIGINT,

  session_code TEXT NOT NULL UNIQUE,
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  session_time TEXT,
  status TEXT NOT NULL DEFAULT 'draft',

  has_3d_scan BOOLEAN NOT NULL DEFAULT FALSE,
  has_plantar_csv BOOLEAN NOT NULL DEFAULT FALSE,
  has_insole_photo BOOLEAN NOT NULL DEFAULT FALSE,
  order_created BOOLEAN NOT NULL DEFAULT FALSE,

  clinical_info_completed BOOLEAN NOT NULL DEFAULT FALSE,
  design_form_completed BOOLEAN NOT NULL DEFAULT FALSE,

  completed_at TIMESTAMPTZ,
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS measurement_sessions_patient_id_idx
  ON public.measurement_sessions(patient_id);

CREATE INDEX IF NOT EXISTS measurement_sessions_expert_user_id_idx
  ON public.measurement_sessions(expert_user_id);

CREATE INDEX IF NOT EXISTS measurement_sessions_assigned_optityou_user_id_idx
  ON public.measurement_sessions(assigned_optityou_user_id);

ALTER TABLE public.measurement_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own measurement sessions"
  ON public.measurement_sessions
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR assigned_optityou_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own measurement sessions"
  ON public.measurement_sessions
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own measurement sessions"
  ON public.measurement_sessions
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR assigned_optityou_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER measurement_sessions_updated_at
  BEFORE UPDATE ON public.measurement_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();