-- QR onboarding is public until authentication, so direct table SELECTs are
-- unsuitable: they either fail RLS or require exposing every invite row.
-- These token-scoped functions treat the random invite token as the lookup
-- credential and keep the claim operation atomic.

CREATE OR REPLACE FUNCTION public.get_patient_invite_by_token(
  p_token TEXT
)
RETURNS TABLE (
  id BIGINT,
  patient_id BIGINT,
  session_id BIGINT,
  expert_user_id BIGINT,
  email TEXT,
  token TEXT,
  status TEXT,
  expires_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    pi.id,
    pi.patient_id,
    pi.session_id,
    pi.expert_user_id,
    pi.email,
    pi.token,
    pi.status,
    pi.expires_at,
    pi.used_at,
    pi.created_at,
    pi.updated_at
  FROM public.patient_invites AS pi
  WHERE pi.token = NULLIF(BTRIM(p_token), '')
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_patient_invite_by_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_patient_invite_by_token(TEXT)
  TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.claim_patient_invite(
  p_token TEXT
)
RETURNS TABLE (
  id BIGINT,
  patient_id BIGINT,
  session_id BIGINT,
  expert_user_id BIGINT,
  email TEXT,
  token TEXT,
  status TEXT,
  expires_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_user_id UUID := auth.uid();
  v_invite public.patient_invites%ROWTYPE;
BEGIN
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT pi.*
  INTO v_invite
  FROM public.patient_invites AS pi
  WHERE pi.token = NULLIF(BTRIM(p_token), '')
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_invite.status <> 'pending' THEN
    RAISE EXCEPTION 'invite_not_pending'
      USING ERRCODE = '22023';
  END IF;

  IF v_invite.expires_at <= NOW() THEN
    RAISE EXCEPTION 'invite_expired'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.patients AS p
  SET
    auth_user_id = v_auth_user_id,
    updated_at = NOW()
  WHERE p.id = v_invite.patient_id
    AND (p.auth_user_id IS NULL OR p.auth_user_id = v_auth_user_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'patient_already_linked_to_another_user'
      USING ERRCODE = '23505';
  END IF;

  UPDATE public.patient_invites AS pi
  SET
    status = 'used',
    used_at = NOW(),
    updated_at = NOW()
  WHERE pi.id = v_invite.id
  RETURNING pi.* INTO v_invite;

  RETURN QUERY
  SELECT
    v_invite.id,
    v_invite.patient_id,
    v_invite.session_id,
    v_invite.expert_user_id,
    v_invite.email,
    v_invite.token,
    v_invite.status,
    v_invite.expires_at,
    v_invite.used_at,
    v_invite.created_at,
    v_invite.updated_at;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_patient_invite(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_patient_invite(TEXT) TO authenticated;
