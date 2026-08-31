ALTER TABLE public.patient_consent_requests
  ADD COLUMN IF NOT EXISTS patient_name TEXT;
