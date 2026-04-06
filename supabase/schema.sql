-- ============================================================
-- OY Dashboard — Supabase Schema
-- Run this in the Supabase SQL Editor (in order).
-- ============================================================

-- ============================================================
-- 1. ROLES
-- ============================================================
CREATE TABLE public.roles (
  id        BIGSERIAL PRIMARY KEY,
  role_code TEXT UNIQUE NOT NULL,
  role_name TEXT        NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.roles (role_code, role_name) VALUES
  ('expert',      'Uzman'),
  ('customer',    'Müşteri'),
  ('optiYouTeam', 'OptiYou Ekibi');

-- ============================================================
-- 2. CLINICS
-- ============================================================
CREATE TABLE public.clinics (
  id          BIGSERIAL PRIMARY KEY,
  clinic_code TEXT UNIQUE NOT NULL,
  clinic_name TEXT        NOT NULL,
  clinic_type TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. USER PROFILES  (extends auth.users via foreign key)
-- ============================================================
CREATE TABLE public.user_profiles (
  id                      BIGSERIAL PRIMARY KEY,
  auth_id                 UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id                 BIGINT REFERENCES public.roles(id),
  clinic_id               BIGINT REFERENCES public.clinics(id),
  first_name              TEXT        NOT NULL,
  last_name               TEXT        NOT NULL,
  username                TEXT UNIQUE,
  phone                   TEXT,
  title                   TEXT,
  commission_profile_name TEXT,
  is_active               BOOLEAN     DEFAULT TRUE,
  last_login_at           TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. VIEW — user_profiles_full
--    Fields match AppUser.fromMap() exactly.
--    AuthService queries this view filtered by auth_id.
-- ============================================================
CREATE VIEW public.user_profiles_full AS
SELECT
  up.id                       AS user_id,
  up.role_id,
  up.clinic_id,
  up.first_name,
  up.last_name,
  au.email,
  up.username,
  up.phone,
  up.title,
  up.commission_profile_name,
  r.role_code,
  r.role_name,
  c.clinic_code,
  c.clinic_name,
  c.clinic_type,
  up.is_active,
  up.last_login_at,
  up.created_at,
  up.updated_at,
  up.auth_id                             -- used by AuthService to filter by current user
FROM public.user_profiles up
JOIN  auth.users au ON au.id  = up.auth_id
LEFT JOIN public.roles   r  ON r.id   = up.role_id
LEFT JOIN public.clinics c  ON c.id   = up.clinic_id;

-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinics       ENABLE ROW LEVEL SECURITY;

-- Users can read/update only their own profile
CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = auth_id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = auth_id);

-- All authenticated users can read roles and clinics
CREATE POLICY "Authenticated users can read roles"
  ON public.roles FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "Authenticated users can read clinics"
  ON public.clinics FOR SELECT
  TO authenticated USING (true);

-- ============================================================
-- 6. TRIGGER — auto-create a minimal profile on signup
--    The profile can be completed later via admin panel / form.
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    auth_id,
    first_name,
    last_name,
    role_id
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Yeni'),
    COALESCE(NEW.raw_user_meta_data->>'last_name',  'Kullanıcı'),
    (SELECT id FROM public.roles WHERE role_code = 'customer' LIMIT 1)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 7. TRIGGER — keep updated_at fresh on user_profiles
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER clinics_updated_at
  BEFORE UPDATE ON public.clinics
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
