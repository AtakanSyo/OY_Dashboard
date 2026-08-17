CREATE TABLE IF NOT EXISTS public.payment_checkout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_id BIGINT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  session_id BIGINT NOT NULL REFERENCES public.measurement_sessions(id) ON DELETE RESTRICT,
  address_id BIGINT NOT NULL REFERENCES public.customer_addresses(id) ON DELETE RESTRICT,

  clinic_id BIGINT,
  expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  address_snapshot JSONB NOT NULL,

  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_type TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'TRY',
  gross_amount NUMERIC(12,2) NOT NULL,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount NUMERIC(12,2) NOT NULL,

  conversation_id TEXT NOT NULL UNIQUE,
  provider_token TEXT UNIQUE,
  provider_payment_id TEXT,
  provider_response JSONB,
  return_url TEXT,
  checkout_status TEXT NOT NULL DEFAULT 'created',
  error_code TEXT,
  error_message TEXT,
  order_id BIGINT UNIQUE REFERENCES public.orders(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at TIMESTAMPTZ,

  CONSTRAINT payment_checkout_status_check CHECK (
    checkout_status IN (
      'created', 'initialized', 'pending', 'paid', 'failed', 'cancelled'
    )
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS payment_checkout_provider_payment_id_uidx
  ON public.payment_checkout_sessions(provider_payment_id)
  WHERE provider_payment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS payment_checkout_auth_user_id_idx
  ON public.payment_checkout_sessions(auth_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS payment_checkout_patient_id_idx
  ON public.payment_checkout_sessions(patient_id, created_at DESC);

ALTER TABLE public.payment_checkout_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own payment checkouts"
  ON public.payment_checkout_sessions
  FOR SELECT
  USING (auth_user_id = auth.uid());

CREATE TRIGGER payment_checkout_sessions_updated_at
  BEFORE UPDATE ON public.payment_checkout_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.finalize_paid_checkout(
  p_checkout_id UUID,
  p_provider_payment_id TEXT,
  p_provider_response JSONB
)
RETURNS TABLE(order_id BIGINT, order_no TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_checkout public.payment_checkout_sessions%ROWTYPE;
  v_order_id BIGINT;
  v_order_no TEXT;
BEGIN
  SELECT *
    INTO v_checkout
    FROM public.payment_checkout_sessions
   WHERE id = p_checkout_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment checkout not found.';
  END IF;

  IF v_checkout.order_id IS NOT NULL THEN
    RETURN QUERY
      SELECT o.id, o.order_no
        FROM public.orders o
       WHERE o.id = v_checkout.order_id;
    RETURN;
  END IF;

  IF p_provider_payment_id IS NULL OR BTRIM(p_provider_payment_id) = '' THEN
    RAISE EXCEPTION 'Provider payment id is required.';
  END IF;

  v_order_no := 'OY-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
    UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 8));

  INSERT INTO public.orders (
    session_id,
    patient_id,
    clinic_id,
    expert_user_id,
    delivery_address_id,
    delivery_address_snapshot,
    order_no,
    product_type,
    order_status,
    currency_code,
    gross_amount,
    discount_amount,
    net_amount,
    ordered_at
  ) VALUES (
    v_checkout.session_id,
    v_checkout.patient_id,
    v_checkout.clinic_id,
    v_checkout.expert_user_id,
    v_checkout.address_id,
    v_checkout.address_snapshot,
    v_order_no,
    v_checkout.product_type,
    'pending',
    v_checkout.currency_code,
    v_checkout.gross_amount,
    v_checkout.discount_amount,
    v_checkout.net_amount,
    NOW()
  )
  RETURNING id INTO v_order_id;

  UPDATE public.payment_checkout_sessions
     SET checkout_status = 'paid',
         provider_payment_id = p_provider_payment_id,
         provider_response = p_provider_response,
         order_id = v_order_id,
         paid_at = NOW(),
         error_code = NULL,
         error_message = NULL
   WHERE id = p_checkout_id;

  UPDATE public.measurement_sessions
     SET order_created = TRUE
   WHERE id = v_checkout.session_id;

  RETURN QUERY SELECT v_order_id, v_order_no;
END;
$$;

REVOKE ALL ON FUNCTION public.finalize_paid_checkout(UUID, TEXT, JSONB)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_paid_checkout(UUID, TEXT, JSONB)
  TO service_role;
