CREATE TABLE IF NOT EXISTS public.patients (
  id BIGSERIAL PRIMARY KEY,

  clinic_id BIGINT,
  created_by_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  patient_code TEXT UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  gender TEXT,
  birth_date DATE,
  notes TEXT,

  auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS patients_created_by_user_id_idx
  ON public.patients(created_by_user_id);

CREATE INDEX IF NOT EXISTS patients_auth_user_id_idx
  ON public.patients(auth_user_id);

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own patients"
  ON public.patients
  FOR SELECT
  USING (
    created_by_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR auth_user_id = auth.uid()
  );

CREATE POLICY "Experts can insert own patients"
  ON public.patients
  FOR INSERT
  WITH CHECK (
    created_by_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own patients"
  ON public.patients
  FOR UPDATE
  USING (
    created_by_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

ALTER TABLE public.analysis_results
ADD COLUMN IF NOT EXISTS patient_id BIGINT REFERENCES public.patients(id) ON DELETE CASCADE;

ALTER TABLE public.analysis_results
ADD COLUMN IF NOT EXISTS expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS analysis_results_patient_id_idx
  ON public.analysis_results(patient_id);

CREATE INDEX IF NOT EXISTS analysis_results_expert_user_id_idx
  ON public.analysis_results(expert_user_id);

DROP POLICY IF EXISTS "Users can read own analysis results"
  ON public.analysis_results;

DROP POLICY IF EXISTS "Users can insert own analysis results"
  ON public.analysis_results;

DROP POLICY IF EXISTS "Users can update own analysis results"
  ON public.analysis_results;

CREATE POLICY "Users and experts can read related analysis results"
  ON public.analysis_results
  FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE auth_user_id = auth.uid()
      OR created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users and experts can insert related analysis results"
  ON public.analysis_results
  FOR INSERT
  WITH CHECK (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users and experts can update related analysis results"
  ON public.analysis_results
  FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE TRIGGER patients_updated_at
  BEFORE UPDATE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();