-- ============================================================
-- Migration: fix role_code casing + update trigger to read
-- role_code from signup metadata.
-- Run this in Supabase SQL Editor if you already ran schema.sql.
-- ============================================================

-- 1. Fix role code values to match Flutter RoleCodes constants
UPDATE public.roles SET role_code = 'EXPERT'       WHERE role_code = 'expert';
UPDATE public.roles SET role_code = 'CUSTOMER'     WHERE role_code = 'customer';
UPDATE public.roles SET role_code = 'OPTIYOU_TEAM' WHERE role_code = 'optiYouTeam';

-- 2. Update trigger to pick role from signup metadata (falls back to CUSTOMER)
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
    (
      SELECT id FROM public.roles
      WHERE role_code = COALESCE(
        NULLIF(TRIM(NEW.raw_user_meta_data->>'role_code'), ''),
        'CUSTOMER'
      )
      LIMIT 1
    )
  );
  RETURN NEW;
END;
$$;
