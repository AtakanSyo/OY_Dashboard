-- OptiYou team members must be able to inspect an approved measurement while
-- it is waiting in the measurement pool. Once an order/assignment exists, the
-- existing assignee-only access rule continues to apply.

CREATE OR REPLACE FUNCTION public.can_current_user_access_session(
  p_session_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_profiles up
    JOIN public.roles r ON r.id = up.role_id
    JOIN public.measurement_sessions ms ON ms.id = p_session_id
    WHERE up.auth_id = auth.uid()
      AND up.is_active IS DISTINCT FROM FALSE
      AND r.role_code = 'OPTIYOU_TEAM'
      AND (
        ms.assigned_optityou_user_id = up.id
        OR EXISTS (
          SELECT 1
          FROM public.orders o
          WHERE o.session_id = ms.id
            AND o.assigned_optityou_user_id = up.id
        )
        OR (
          ms.order_created IS TRUE
          AND ms.assigned_optityou_user_id IS NULL
          AND NOT EXISTS (
            SELECT 1
            FROM public.orders o
            WHERE o.session_id = ms.id
          )
        )
      )
  );
$$;

-- Backward-compatible wrapper used by the existing RLS policies.
CREATE OR REPLACE FUNCTION public.is_current_user_assigned_to_session(
  p_session_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.can_current_user_access_session(p_session_id);
$$;

CREATE OR REPLACE FUNCTION public.can_current_user_write_session_input(
  p_session_id BIGINT,
  p_expert_user_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    WHERE ms.id = p_session_id
      AND ms.expert_user_id = p_expert_user_id
      AND public.can_current_user_access_session(ms.id)
  );
$$;

CREATE OR REPLACE FUNCTION public.is_current_user_assigned_to_patient(
  p_patient_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.measurement_sessions ms
    WHERE ms.patient_id = p_patient_id
      AND public.can_current_user_access_session(ms.id)
  );
$$;

REVOKE ALL ON FUNCTION public.can_current_user_access_session(BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.can_current_user_access_session(BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  TO authenticated;

DROP POLICY IF EXISTS "OptiYou team can read accessible measurement sessions"
  ON public.measurement_sessions;
CREATE POLICY "OptiYou team can read accessible measurement sessions"
  ON public.measurement_sessions
  FOR SELECT
  TO authenticated
  USING (public.can_current_user_access_session(id));

DROP POLICY IF EXISTS "OptiYou team can update accessible measurement sessions"
  ON public.measurement_sessions;
CREATE POLICY "OptiYou team can update accessible measurement sessions"
  ON public.measurement_sessions
  FOR UPDATE
  TO authenticated
  USING (public.can_current_user_access_session(id))
  WITH CHECK (public.can_current_user_access_session(id));
