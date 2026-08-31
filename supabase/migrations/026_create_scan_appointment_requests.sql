-- Public site "Tarama Yap" akışının talep kayıtları.
--
-- İki tablo:
--   * scan_appointment_requests  — bireysel randevu talepleri
--   * corporate_scan_requests    — kurumsal (tarayıcı satın alma / B2B hizmet)
--
-- Her iki tablo da giriş yapmamış ziyaretçiler tarafından yalnızca INSERT
-- edilebilir; KVKK onayı verilmeden kayıt açılamaz. Okuma/güncelleme/silme
-- yalnızca OPTIYOU ekibine açıktır (public.is_optityou_team_member).

-- ── Bireysel randevu talepleri ──────────────────────────────────────────────
CREATE TABLE public.scan_appointment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  location TEXT NOT NULL CHECK (location IN ('LLT', 'OPTIYOU', 'IZTU_DML')),
  appointment_date DATE NOT NULL,
  appointment_time TEXT NOT NULL,
  note TEXT,
  kvkk_consent BOOLEAN NOT NULL DEFAULT FALSE,
  email_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Kurumsal talepler ──────────────────────────────────────────────────────
CREATE TABLE public.corporate_scan_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  person_count INTEGER NOT NULL CHECK (person_count > 0),
  request_type TEXT NOT NULL
    CHECK (request_type IN ('scanner_purchase', 'b2b_service')),
  note TEXT,
  kvkk_consent BOOLEAN NOT NULL DEFAULT FALSE,
  email_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX scan_appointment_requests_created_at_idx
  ON public.scan_appointment_requests (created_at DESC);
CREATE INDEX corporate_scan_requests_created_at_idx
  ON public.corporate_scan_requests (created_at DESC);

ALTER TABLE public.scan_appointment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corporate_scan_requests ENABLE ROW LEVEL SECURITY;

-- Ziyaretçi (anon) ve giriş yapmış kullanıcı yalnızca KVKK onayıyla kayıt açar.
CREATE POLICY "Public can submit scan appointment requests"
  ON public.scan_appointment_requests
  FOR INSERT TO anon, authenticated
  WITH CHECK (kvkk_consent = TRUE);

CREATE POLICY "Public can submit corporate scan requests"
  ON public.corporate_scan_requests
  FOR INSERT TO anon, authenticated
  WITH CHECK (kvkk_consent = TRUE);

-- Talepleri yalnızca OPTIYOU ekibi görüntüleyip yönetir.
CREATE POLICY "Optiyou team manages scan appointment requests"
  ON public.scan_appointment_requests
  FOR ALL TO authenticated
  USING (public.is_optityou_team_member())
  WITH CHECK (public.is_optityou_team_member());

CREATE POLICY "Optiyou team manages corporate scan requests"
  ON public.corporate_scan_requests
  FOR ALL TO authenticated
  USING (public.is_optityou_team_member())
  WITH CHECK (public.is_optityou_team_member());
