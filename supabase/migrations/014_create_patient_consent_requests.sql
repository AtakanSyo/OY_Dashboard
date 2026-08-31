CREATE TABLE IF NOT EXISTS public.patient_consent_requests (
  id BIGSERIAL PRIMARY KEY,

  patient_id BIGINT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  email TEXT NOT NULL,
  patient_name TEXT,
  token TEXT NOT NULL UNIQUE,

  status TEXT NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS patient_consent_requests_patient_id_idx
  ON public.patient_consent_requests(patient_id);

CREATE INDEX IF NOT EXISTS patient_consent_requests_token_idx
  ON public.patient_consent_requests(token);

ALTER TABLE public.patient_consent_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Experts can read own consent requests"
  ON public.patient_consent_requests
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can insert own consent requests"
  ON public.patient_consent_requests
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Experts can update own consent requests"
  ON public.patient_consent_requests
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

-- The patient opens the consent link unauthenticated; the token itself
-- (32 random bytes) is the credential, mirroring the patient_invites model.
CREATE POLICY "Anyone can read a consent request by token"
  ON public.patient_consent_requests
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Anon may only flip a still-pending, non-expired request to accepted --
-- no other field or row state is reachable through this policy.
CREATE POLICY "Anyone can accept a pending consent request by token"
  ON public.patient_consent_requests
  FOR UPDATE
  TO anon, authenticated
  USING (status = 'pending' AND expires_at > NOW())
  WITH CHECK (status = 'accepted');

CREATE TRIGGER patient_consent_requests_updated_at
  BEFORE UPDATE ON public.patient_consent_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
