-- Public tarama formlarını doğrudan tablo erişiminden sunucu kontrollü
-- Edge Function akışına taşır.

-- SECURITY DEFINER fonksiyonu güvenli search_path ve en dar EXECUTE
-- ayrıcalıklarıyla yeniden tanımlar. Fonksiyon diğer OPTIYOU ekip
-- politikaları tarafından da kullanılmaya devam eder.
CREATE OR REPLACE FUNCTION public.is_optityou_team_member()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_profiles AS up
    JOIN public.roles AS r ON r.id = up.role_id
    WHERE up.auth_id = auth.uid()
      AND up.is_active = TRUE
      AND r.role_code = 'OPTIYOU_TEAM'
  );
$$;

REVOKE ALL ON FUNCTION public.is_optityou_team_member() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_optityou_team_member()
  TO authenticated, service_role;

ALTER TABLE public.scan_appointment_requests
  RENAME COLUMN kvkk_consent TO privacy_notice_acknowledged;
ALTER TABLE public.corporate_scan_requests
  RENAME COLUMN kvkk_consent TO privacy_notice_acknowledged;

ALTER TABLE public.scan_appointment_requests
  ADD COLUMN client_request_id UUID,
  ADD COLUMN request_source_hash TEXT,
  ADD COLUMN email_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN email_attempted_at TIMESTAMPTZ,
  ADD COLUMN email_dispatch_error TEXT;

ALTER TABLE public.corporate_scan_requests
  ADD COLUMN client_request_id UUID,
  ADD COLUMN request_source_hash TEXT,
  ADD COLUMN email_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN email_attempted_at TIMESTAMPTZ,
  ADD COLUMN email_dispatch_error TEXT;

UPDATE public.scan_appointment_requests
SET client_request_id = gen_random_uuid()
WHERE client_request_id IS NULL;

UPDATE public.corporate_scan_requests
SET client_request_id = gen_random_uuid()
WHERE client_request_id IS NULL;

UPDATE public.scan_appointment_requests
SET email_status = 'sent'
WHERE email_dispatched = TRUE AND email_status = 'pending';

UPDATE public.corporate_scan_requests
SET email_status = 'sent'
WHERE email_dispatched = TRUE AND email_status = 'pending';

ALTER TABLE public.scan_appointment_requests
  ALTER COLUMN client_request_id SET NOT NULL,
  ADD CONSTRAINT scan_appointment_requests_client_request_id_key
    UNIQUE (client_request_id),
  ADD CONSTRAINT scan_appointment_requests_email_status_check
    CHECK (email_status IN ('pending', 'sent', 'failed')),
  ADD CONSTRAINT scan_appointment_requests_source_hash_check
    CHECK (request_source_hash IS NULL OR length(request_source_hash) = 64),
  ADD CONSTRAINT scan_appointment_requests_full_name_length_check
    CHECK (length(full_name) BETWEEN 2 AND 120),
  ADD CONSTRAINT scan_appointment_requests_phone_length_check
    CHECK (length(phone) BETWEEN 10 AND 32),
  ADD CONSTRAINT scan_appointment_requests_email_length_check
    CHECK (length(email) BETWEEN 3 AND 320),
  ADD CONSTRAINT scan_appointment_requests_time_check
    CHECK (
      appointment_time ~ '^(11|12|13|14|15|16):(00|15|30|45)$'
    ),
  ADD CONSTRAINT scan_appointment_requests_note_length_check
    CHECK (note IS NULL OR length(note) <= 1000),
  ADD CONSTRAINT scan_appointment_requests_privacy_notice_check
    CHECK (privacy_notice_acknowledged = TRUE);

ALTER TABLE public.corporate_scan_requests
  ALTER COLUMN client_request_id SET NOT NULL,
  ADD CONSTRAINT corporate_scan_requests_client_request_id_key
    UNIQUE (client_request_id),
  ADD CONSTRAINT corporate_scan_requests_email_status_check
    CHECK (email_status IN ('pending', 'sent', 'failed')),
  ADD CONSTRAINT corporate_scan_requests_source_hash_check
    CHECK (request_source_hash IS NULL OR length(request_source_hash) = 64),
  ADD CONSTRAINT corporate_scan_requests_company_name_length_check
    CHECK (length(company_name) BETWEEN 2 AND 160),
  ADD CONSTRAINT corporate_scan_requests_contact_name_length_check
    CHECK (length(contact_name) BETWEEN 2 AND 120),
  ADD CONSTRAINT corporate_scan_requests_phone_length_check
    CHECK (length(phone) BETWEEN 10 AND 32),
  ADD CONSTRAINT corporate_scan_requests_email_length_check
    CHECK (length(email) BETWEEN 3 AND 320),
  ADD CONSTRAINT corporate_scan_requests_person_count_check_v2
    CHECK (person_count BETWEEN 1 AND 100000),
  ADD CONSTRAINT corporate_scan_requests_note_length_check
    CHECK (note IS NULL OR length(note) <= 1000),
  ADD CONSTRAINT corporate_scan_requests_privacy_notice_check
    CHECK (privacy_notice_acknowledged = TRUE);

CREATE INDEX scan_appointment_requests_source_created_idx
  ON public.scan_appointment_requests (request_source_hash, created_at DESC);
CREATE INDEX scan_appointment_requests_email_created_idx
  ON public.scan_appointment_requests (lower(email), created_at DESC);
CREATE INDEX corporate_scan_requests_source_created_idx
  ON public.corporate_scan_requests (request_source_hash, created_at DESC);
CREATE INDEX corporate_scan_requests_email_created_idx
  ON public.corporate_scan_requests (lower(email), created_at DESC);

-- Public istemci artık tabloya doğrudan yazmaz. Edge Function, sunucu gizli
-- anahtarıyla kaydı oluşturur ve e-posta durumunu günceller.
DROP POLICY IF EXISTS "Public can submit scan appointment requests"
  ON public.scan_appointment_requests;
DROP POLICY IF EXISTS "Public can submit corporate scan requests"
  ON public.corporate_scan_requests;

REVOKE ALL ON TABLE public.scan_appointment_requests FROM anon;
REVOKE ALL ON TABLE public.corporate_scan_requests FROM anon;

REVOKE ALL ON TABLE public.scan_appointment_requests FROM authenticated;
REVOKE ALL ON TABLE public.corporate_scan_requests FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.scan_appointment_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.corporate_scan_requests TO authenticated;

GRANT ALL ON TABLE public.scan_appointment_requests TO service_role;
GRANT ALL ON TABLE public.corporate_scan_requests TO service_role;

COMMENT ON COLUMN public.scan_appointment_requests.request_source_hash IS
  'Hız sınırı için tuzlanmış kaynak özeti; ham IP adresi tutulmaz.';
COMMENT ON COLUMN public.corporate_scan_requests.request_source_hash IS
  'Hız sınırı için tuzlanmış kaynak özeti; ham IP adresi tutulmaz.';
