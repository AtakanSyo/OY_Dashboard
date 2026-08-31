CREATE TABLE IF NOT EXISTS public.patient_invites (
  id BIGSERIAL PRIMARY KEY,

  patient_id BIGINT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  session_id BIGINT REFERENCES public.measurement_sessions(id) ON DELETE CASCADE,
  expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  email TEXT,
  token TEXT NOT NULL UNIQUE,

  status TEXT NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS patient_invites_patient_id_idx
  ON public.patient_invites(patient_id);

CREATE INDEX IF NOT EXISTS patient_invites_session_id_idx
  ON public.patient_invites(session_id);

CREATE INDEX IF NOT EXISTS patient_invites_token_idx
  ON public.patient_invites(token);

ALTER TABLE public.patient_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own patient invites"
  ON public.patient_invites
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own patient invites"
  ON public.patient_invites
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own patient invites"
  ON public.patient_invites
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER patient_invites_updated_at
  BEFORE UPDATE ON public.patient_invites
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();