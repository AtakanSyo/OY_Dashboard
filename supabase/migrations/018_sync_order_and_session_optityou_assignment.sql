-- Keep the OptiYou assignment on an order and its measurement session in sync.
-- Migration 017 originally checked only measurement_sessions, while the order
-- creation flow stores the assignee on orders. That mismatch made related
-- session inputs appear empty because RLS filtered them out.

WITH latest_order_assignment AS (
  SELECT DISTINCT ON (o.session_id)
    o.session_id,
    o.assigned_optityou_user_id
  FROM public.orders o
  WHERE o.session_id IS NOT NULL
    AND o.assigned_optityou_user_id IS NOT NULL
  ORDER BY o.session_id, o.ordered_at DESC NULLS LAST, o.id DESC
)
UPDATE public.measurement_sessions ms
SET assigned_optityou_user_id = loa.assigned_optityou_user_id
FROM latest_order_assignment loa
WHERE ms.id = loa.session_id
  AND ms.assigned_optityou_user_id IS DISTINCT FROM loa.assigned_optityou_user_id;

CREATE OR REPLACE FUNCTION public.is_current_user_assigned_to_session(
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
    WHERE up.auth_id = auth.uid()
      AND (
        EXISTS (
          SELECT 1
          FROM public.measurement_sessions ms
          WHERE ms.id = p_session_id
            AND ms.assigned_optityou_user_id = up.id
        )
        OR EXISTS (
          SELECT 1
          FROM public.orders o
          WHERE o.session_id = p_session_id
            AND o.assigned_optityou_user_id = up.id
        )
      )
  );
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
    JOIN public.user_profiles up
      ON up.auth_id = auth.uid()
    WHERE ms.id = p_session_id
      AND ms.expert_user_id = p_expert_user_id
      AND (
        ms.assigned_optityou_user_id = up.id
        OR EXISTS (
          SELECT 1
          FROM public.orders o
          WHERE o.session_id = ms.id
            AND o.assigned_optityou_user_id = up.id
        )
      )
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
    FROM public.user_profiles up
    WHERE up.auth_id = auth.uid()
      AND (
        EXISTS (
          SELECT 1
          FROM public.measurement_sessions ms
          WHERE ms.patient_id = p_patient_id
            AND (
              ms.assigned_optityou_user_id = up.id
              OR EXISTS (
                SELECT 1
                FROM public.orders o
                WHERE o.session_id = ms.id
                  AND o.assigned_optityou_user_id = up.id
              )
            )
        )
        OR EXISTS (
          SELECT 1
          FROM public.orders o
          WHERE o.patient_id = p_patient_id
            AND o.assigned_optityou_user_id = up.id
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_session(BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_current_user_write_session_input(BIGINT, BIGINT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_assigned_to_patient(BIGINT)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_order_optityou_assignment_to_session()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.session_id IS NOT NULL THEN
    UPDATE public.measurement_sessions
    SET assigned_optityou_user_id = NEW.assigned_optityou_user_id
    WHERE id = NEW.session_id
      AND assigned_optityou_user_id IS DISTINCT FROM NEW.assigned_optityou_user_id;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_order_optityou_assignment_to_session()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS orders_sync_optityou_assignment_to_session
  ON public.orders;

CREATE TRIGGER orders_sync_optityou_assignment_to_session
  AFTER INSERT OR UPDATE OF session_id, assigned_optityou_user_id
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_order_optityou_assignment_to_session();
