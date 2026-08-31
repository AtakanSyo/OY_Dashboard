CREATE TABLE IF NOT EXISTS public.orthotic_design_forms (
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

  heel_pad BOOLEAN NOT NULL DEFAULT FALSE,
  deep_heel_cup_mm NUMERIC,
  heel_raise_mm NUMERIC,

  medial_arch_support BOOLEAN NOT NULL DEFAULT FALSE,
  metatarsal_pad BOOLEAN NOT NULL DEFAULT FALSE,
  transverse_arch_support BOOLEAN NOT NULL DEFAULT FALSE,

  posterior_relief_mm NUMERIC,

  morton_relief BOOLEAN NOT NULL DEFAULT FALSE,
  bunion_pad BOOLEAN NOT NULL DEFAULT FALSE,

  expert_notes TEXT,

  ai_recommendation_json TEXT,

  approved_for_order BOOLEAN NOT NULL DEFAULT FALSE,

  form_json JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT orthotic_design_forms_unique_session
    UNIQUE(session_id)
);

CREATE INDEX IF NOT EXISTS orthotic_design_forms_session_idx
  ON public.orthotic_design_forms(session_id);

CREATE INDEX IF NOT EXISTS orthotic_design_forms_patient_idx
  ON public.orthotic_design_forms(patient_id);

ALTER TABLE public.orthotic_design_forms
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own orthotic forms"
  ON public.orthotic_design_forms
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own orthotic forms"
  ON public.orthotic_design_forms
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own orthotic forms"
  ON public.orthotic_design_forms
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER orthotic_design_forms_updated_at
  BEFORE UPDATE ON public.orthotic_design_forms
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();