CREATE TABLE IF NOT EXISTS public.anthropometric_clinical_infos (
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

  height_cm NUMERIC,
  weight_kg NUMERIC,
  bmi NUMERIC,
  shoe_size_eu NUMERIC,

  profession TEXT,
  daily_standing_hours NUMERIC,
  job_description TEXT,

  does_sport BOOLEAN NOT NULL DEFAULT FALSE,
  sport_description TEXT,

  current_complaint TEXT,
  diagnosis_pre_diagnosis TEXT,

  has_diabetes BOOLEAN NOT NULL DEFAULT FALSE,
  diabetes_note TEXT,

  hallux_valgus BOOLEAN NOT NULL DEFAULT FALSE,
  heel_spur BOOLEAN NOT NULL DEFAULT FALSE,
  flat_foot BOOLEAN NOT NULL DEFAULT FALSE,
  pes_cavus BOOLEAN NOT NULL DEFAULT FALSE,
  morton_neuroma BOOLEAN NOT NULL DEFAULT FALSE,
  achilles_problem BOOLEAN NOT NULL DEFAULT FALSE,
  metatarsal_pain BOOLEAN NOT NULL DEFAULT FALSE,

  other_pathologies TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT anthropometric_clinical_infos_unique_session
    UNIQUE(session_id)
);

CREATE INDEX IF NOT EXISTS anthropometric_infos_session_idx
  ON public.anthropometric_clinical_infos(session_id);

CREATE INDEX IF NOT EXISTS anthropometric_infos_patient_idx
  ON public.anthropometric_clinical_infos(patient_id);

ALTER TABLE public.anthropometric_clinical_infos
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id
      FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id
      FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own anthropometric infos"
  ON public.anthropometric_clinical_infos
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id
      FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER anthropometric_infos_updated_at
  BEFORE UPDATE ON public.anthropometric_clinical_infos
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();