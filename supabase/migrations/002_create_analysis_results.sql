CREATE TABLE IF NOT EXISTS public.analysis_results (
  id BIGSERIAL PRIMARY KEY,

  user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  session_code TEXT NOT NULL,

  analysis_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  location_label TEXT,

  overall_summary TEXT,
  general_risk_note TEXT,

  left_foot JSONB NOT NULL DEFAULT '{}'::jsonb,
  right_foot JSONB NOT NULL DEFAULT '{}'::jsonb,
  metrics JSONB NOT NULL DEFAULT '[]'::jsonb,
  recommendations JSONB NOT NULL DEFAULT '[]'::jsonb,
  visuals JSONB NOT NULL DEFAULT '{}'::jsonb,
  parsed_report JSONB,
  pressure_summary JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT analysis_results_user_session_unique
    UNIQUE (user_id, session_code)
);

CREATE INDEX IF NOT EXISTS analysis_results_user_id_idx
  ON public.analysis_results(user_id);

CREATE INDEX IF NOT EXISTS analysis_results_session_code_idx
  ON public.analysis_results(session_code);

ALTER TABLE public.analysis_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own analysis results"
  ON public.analysis_results
  FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own analysis results"
  ON public.analysis_results
  FOR INSERT
  WITH CHECK (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own analysis results"
  ON public.analysis_results
  FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER analysis_results_updated_at
  BEFORE UPDATE ON public.analysis_results
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();