CREATE TABLE IF NOT EXISTS public.customer_addresses (
  id BIGSERIAL PRIMARY KEY,

  user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  patient_id BIGINT REFERENCES public.patients(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  city TEXT NOT NULL,
  district TEXT NOT NULL,
  address_line TEXT NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT customer_addresses_owner_check
    CHECK (user_id IS NOT NULL OR patient_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS customer_addresses_user_id_idx
  ON public.customer_addresses(user_id);

CREATE INDEX IF NOT EXISTS customer_addresses_patient_id_idx
  ON public.customer_addresses(patient_id);

CREATE TABLE IF NOT EXISTS public.orders (
  id BIGSERIAL PRIMARY KEY,

  session_id BIGINT REFERENCES public.measurement_sessions(id) ON DELETE CASCADE,
  patient_id BIGINT REFERENCES public.patients(id) ON DELETE CASCADE,
  clinic_id BIGINT,
  expert_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  assigned_optityou_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  delivery_address_id BIGINT REFERENCES public.customer_addresses(id) ON DELETE SET NULL,
  delivery_address_snapshot JSONB,

  order_no TEXT NOT NULL UNIQUE,
  product_type TEXT NOT NULL,
  order_status TEXT NOT NULL DEFAULT 'pending',
  currency_code TEXT NOT NULL DEFAULT 'TRY',

  gross_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_amount NUMERIC(12,2) NOT NULL DEFAULT 0,

  ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_session_id_idx
  ON public.orders(session_id);

CREATE INDEX IF NOT EXISTS orders_patient_id_idx
  ON public.orders(patient_id);

CREATE INDEX IF NOT EXISTS orders_expert_user_id_idx
  ON public.orders(expert_user_id);

CREATE INDEX IF NOT EXISTS orders_status_idx
  ON public.orders(order_status);

ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users and experts can read related customer addresses"
  ON public.customer_addresses
  FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE auth_user_id = auth.uid()
      OR created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users and experts can insert related customer addresses"
  ON public.customer_addresses
  FOR INSERT
  WITH CHECK (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users and experts can update related customer addresses"
  ON public.customer_addresses
  FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users and experts can read related orders"
  ON public.orders
  FOR SELECT
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR assigned_optityou_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR patient_id IN (
      SELECT id FROM public.patients
      WHERE auth_user_id = auth.uid()
      OR created_by_user_id IN (
        SELECT id FROM public.user_profiles
        WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Experts can insert related orders"
  ON public.orders
  FOR INSERT
  WITH CHECK (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Users and experts can update related orders"
  ON public.orders
  FOR UPDATE
  USING (
    expert_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
    OR assigned_optityou_user_id IN (
      SELECT id FROM public.user_profiles
      WHERE auth_id = auth.uid()
    )
  );

CREATE TRIGGER customer_addresses_updated_at
  BEFORE UPDATE ON public.customer_addresses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();