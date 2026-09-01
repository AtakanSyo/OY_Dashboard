-- OPTIYOU public tarama/randevu formları
-- Supabase Dashboard > SQL Editor için güvenli kurulum/yükseltme betiği.
--
-- Bu dosya:
--   * tablolar yoksa son şemayla oluşturur,
--   * migration 026 daha önce uygulanmışsa yapıyı 027 seviyesine yükseltir,
--   * yeniden çalıştırılabilir,
--   * anon rolünün doğrudan tablo erişimini kapatır,
--   * yalnızca OPTIYOU ekip üyelerine RLS üzerinden yönetim izni verir,
--   * Edge Function'ın service_role / secret key ile çalışmasını sağlar.
--
-- UYARI: SQL Editor'da çalıştırmak repo migration geçmişini otomatik olarak
-- "applied" işaretlemez. Başarılı smoke testten sonra `supabase migration list`
-- çıktısı incelenmeden `supabase db push` çalıştırılmamalıdır.

BEGIN;

-- Ekip üyeliği kontrolü. Fonksiyon SECURITY DEFINER olduğu için tüm nesneler
-- açık şemayla belirtilir ve yalnızca gerekli rollere EXECUTE verilir.
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

-- Tablolar henüz yoksa doğrudan güvenli son şemayla oluşturulur.
CREATE TABLE IF NOT EXISTS public.scan_appointment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  location TEXT NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time TEXT NOT NULL,
  note TEXT,
  privacy_notice_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
  email_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
  client_request_id UUID NOT NULL,
  request_source_hash TEXT,
  email_status TEXT NOT NULL DEFAULT 'pending',
  email_attempted_at TIMESTAMPTZ,
  email_dispatch_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.corporate_scan_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  person_count INTEGER NOT NULL,
  request_type TEXT NOT NULL,
  note TEXT,
  privacy_notice_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
  email_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
  client_request_id UUID NOT NULL,
  request_source_hash TEXT,
  email_status TEXT NOT NULL DEFAULT 'pending',
  email_attempted_at TIMESTAMPTZ,
  email_dispatch_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Eski kvkk_consent alanını veri kaybetmeden yeni, doğru isimle birleştirir.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'scan_appointment_requests'
      AND column_name = 'kvkk_consent'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'scan_appointment_requests'
      AND column_name = 'privacy_notice_acknowledged'
  ) THEN
    ALTER TABLE public.scan_appointment_requests
      RENAME COLUMN kvkk_consent TO privacy_notice_acknowledged;
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'scan_appointment_requests'
      AND column_name = 'kvkk_consent'
  ) THEN
    UPDATE public.scan_appointment_requests
    SET privacy_notice_acknowledged =
      COALESCE(privacy_notice_acknowledged, FALSE)
      OR COALESCE(kvkk_consent, FALSE);
    ALTER TABLE public.scan_appointment_requests DROP COLUMN kvkk_consent;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'corporate_scan_requests'
      AND column_name = 'kvkk_consent'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'corporate_scan_requests'
      AND column_name = 'privacy_notice_acknowledged'
  ) THEN
    ALTER TABLE public.corporate_scan_requests
      RENAME COLUMN kvkk_consent TO privacy_notice_acknowledged;
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'corporate_scan_requests'
      AND column_name = 'kvkk_consent'
  ) THEN
    UPDATE public.corporate_scan_requests
    SET privacy_notice_acknowledged =
      COALESCE(privacy_notice_acknowledged, FALSE)
      OR COALESCE(kvkk_consent, FALSE);
    ALTER TABLE public.corporate_scan_requests DROP COLUMN kvkk_consent;
  END IF;
END;
$$;

-- 026 kurulmuş ortamlarda eksik güvenlik/idempotency alanlarını tamamlar.
ALTER TABLE public.scan_appointment_requests
  ADD COLUMN IF NOT EXISTS privacy_notice_acknowledged BOOLEAN
    NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS client_request_id UUID,
  ADD COLUMN IF NOT EXISTS request_source_hash TEXT,
  ADD COLUMN IF NOT EXISTS email_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS email_attempted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS email_dispatch_error TEXT;

ALTER TABLE public.corporate_scan_requests
  ADD COLUMN IF NOT EXISTS privacy_notice_acknowledged BOOLEAN
    NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS client_request_id UUID,
  ADD COLUMN IF NOT EXISTS request_source_hash TEXT,
  ADD COLUMN IF NOT EXISTS email_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS email_attempted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS email_dispatch_error TEXT;

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
  ALTER COLUMN privacy_notice_acknowledged SET DEFAULT FALSE,
  ALTER COLUMN privacy_notice_acknowledged SET NOT NULL,
  ALTER COLUMN client_request_id SET NOT NULL,
  ALTER COLUMN email_status SET DEFAULT 'pending',
  ALTER COLUMN email_status SET NOT NULL;

ALTER TABLE public.corporate_scan_requests
  ALTER COLUMN privacy_notice_acknowledged SET DEFAULT FALSE,
  ALTER COLUMN privacy_notice_acknowledged SET NOT NULL,
  ALTER COLUMN client_request_id SET NOT NULL,
  ALTER COLUMN email_status SET DEFAULT 'pending',
  ALTER COLUMN email_status SET NOT NULL;

-- Kısıtlar aynı adlarla yenilenir; veri uyumsuzsa transaction tamamen geri
-- alınır ve kısmi kurulum oluşmaz.
ALTER TABLE public.scan_appointment_requests
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_location_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_client_request_id_key,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_email_status_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_source_hash_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_full_name_length_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_phone_length_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_email_length_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_time_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_note_length_check,
  DROP CONSTRAINT IF EXISTS scan_appointment_requests_privacy_notice_check;

ALTER TABLE public.scan_appointment_requests
  ADD CONSTRAINT scan_appointment_requests_location_check
    CHECK (location IN ('LLT', 'OPTIYOU', 'IZTU_DML')),
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
    CHECK (appointment_time ~ '^(11|12|13|14|15|16):(00|15|30|45)$'),
  ADD CONSTRAINT scan_appointment_requests_note_length_check
    CHECK (note IS NULL OR length(note) <= 1000),
  ADD CONSTRAINT scan_appointment_requests_privacy_notice_check
    CHECK (privacy_notice_acknowledged = TRUE);

ALTER TABLE public.corporate_scan_requests
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_request_type_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_person_count_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_person_count_check_v2,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_client_request_id_key,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_email_status_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_source_hash_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_company_name_length_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_contact_name_length_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_phone_length_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_email_length_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_note_length_check,
  DROP CONSTRAINT IF EXISTS corporate_scan_requests_privacy_notice_check;

ALTER TABLE public.corporate_scan_requests
  ADD CONSTRAINT corporate_scan_requests_request_type_check
    CHECK (request_type IN ('scanner_purchase', 'b2b_service')),
  ADD CONSTRAINT corporate_scan_requests_person_count_check
    CHECK (person_count BETWEEN 1 AND 100000),
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
  ADD CONSTRAINT corporate_scan_requests_note_length_check
    CHECK (note IS NULL OR length(note) <= 1000),
  ADD CONSTRAINT corporate_scan_requests_privacy_notice_check
    CHECK (privacy_notice_acknowledged = TRUE);

CREATE INDEX IF NOT EXISTS scan_appointment_requests_created_at_idx
  ON public.scan_appointment_requests (created_at DESC);
CREATE INDEX IF NOT EXISTS scan_appointment_requests_source_created_idx
  ON public.scan_appointment_requests (request_source_hash, created_at DESC);
CREATE INDEX IF NOT EXISTS scan_appointment_requests_email_created_idx
  ON public.scan_appointment_requests (lower(email), created_at DESC);

CREATE INDEX IF NOT EXISTS corporate_scan_requests_created_at_idx
  ON public.corporate_scan_requests (created_at DESC);
CREATE INDEX IF NOT EXISTS corporate_scan_requests_source_created_idx
  ON public.corporate_scan_requests (request_source_hash, created_at DESC);
CREATE INDEX IF NOT EXISTS corporate_scan_requests_email_created_idx
  ON public.corporate_scan_requests (lower(email), created_at DESC);

ALTER TABLE public.scan_appointment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_scan_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can submit scan appointment requests"
  ON public.scan_appointment_requests;
DROP POLICY IF EXISTS "Public can submit corporate scan requests"
  ON public.corporate_scan_requests;
DROP POLICY IF EXISTS "Optiyou team manages scan appointment requests"
  ON public.scan_appointment_requests;
DROP POLICY IF EXISTS "Optiyou team manages corporate scan requests"
  ON public.corporate_scan_requests;

CREATE POLICY "Optiyou team manages scan appointment requests"
  ON public.scan_appointment_requests
  FOR ALL
  TO authenticated
  USING (public.is_optityou_team_member())
  WITH CHECK (public.is_optityou_team_member());

CREATE POLICY "Optiyou team manages corporate scan requests"
  ON public.corporate_scan_requests
  FOR ALL
  TO authenticated
  USING (public.is_optityou_team_member())
  WITH CHECK (public.is_optityou_team_member());

-- Public tarayıcı hiçbir tablo işlemi yapamaz. Kayıt ve e-posta güncellemesi
-- yalnızca Edge Function'ın secret/service rolüyle yapılır.
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

COMMIT;

-- -------------------------------------------------------------------------
-- Sonuç kontrolü: İki satır da aşağıdaki değerleri göstermelidir:
-- rls_enabled=true, anon_* = false, service_* = true,
-- team_policy_count=1, anon_policy_count=0.
-- -------------------------------------------------------------------------
SELECT
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  has_table_privilege('anon', c.oid, 'SELECT') AS anon_select,
  has_table_privilege('anon', c.oid, 'INSERT') AS anon_insert,
  has_table_privilege('anon', c.oid, 'UPDATE') AS anon_update,
  has_table_privilege('anon', c.oid, 'DELETE') AS anon_delete,
  has_table_privilege('service_role', c.oid, 'INSERT') AS service_insert,
  has_table_privilege('service_role', c.oid, 'UPDATE') AS service_update,
  (
    SELECT count(*)
    FROM pg_policies AS p
    WHERE p.schemaname = 'public'
      AND p.tablename = c.relname
      AND p.roles @> ARRAY['authenticated']::name[]
  ) AS team_policy_count,
  (
    SELECT count(*)
    FROM pg_policies AS p
    WHERE p.schemaname = 'public'
      AND p.tablename = c.relname
      AND p.roles @> ARRAY['anon']::name[]
  ) AS anon_policy_count
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'scan_appointment_requests',
    'corporate_scan_requests'
  )
ORDER BY c.relname;
