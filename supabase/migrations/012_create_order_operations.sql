CREATE TABLE IF NOT EXISTS public.order_operation_states (
  id BIGSERIAL PRIMARY KEY,

  order_id BIGINT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  session_id BIGINT REFERENCES public.measurement_sessions(id) ON DELETE SET NULL,
  patient_id BIGINT REFERENCES public.patients(id) ON DELETE SET NULL,
  assigned_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  design_completed BOOLEAN NOT NULL DEFAULT FALSE,
  production_started BOOLEAN NOT NULL DEFAULT FALSE,
  production_completed BOOLEAN NOT NULL DEFAULT FALSE,

  qc_design_match BOOLEAN NOT NULL DEFAULT FALSE,
  qc_measurement_done BOOLEAN NOT NULL DEFAULT FALSE,
  qc_surface_checked BOOLEAN NOT NULL DEFAULT FALSE,
  qc_ready_for_delivery BOOLEAN NOT NULL DEFAULT FALSE,
  qc_note TEXT,

  packaging_completed BOOLEAN NOT NULL DEFAULT FALSE,
  shipping_tracking_no TEXT,

  order_closed BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT order_operation_states_unique_order UNIQUE(order_id)
);

CREATE TABLE IF NOT EXISTS public.order_operation_files (
  id BIGSERIAL PRIMARY KEY,

  order_id BIGINT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  session_id BIGINT REFERENCES public.measurement_sessions(id) ON DELETE SET NULL,
  patient_id BIGINT REFERENCES public.patients(id) ON DELETE SET NULL,
  uploaded_by_user_id BIGINT REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  file_type TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  size_bytes BIGINT,

  local_file_path TEXT,

  storage_bucket TEXT,
  storage_path TEXT,
  public_url TEXT,

  upload_status TEXT NOT NULL DEFAULT 'local',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT order_operation_files_unique_order_type UNIQUE(order_id, file_type)
);

CREATE INDEX IF NOT EXISTS order_operation_states_order_idx
  ON public.order_operation_states(order_id);

CREATE INDEX IF NOT EXISTS order_operation_files_order_idx
  ON public.order_operation_files(order_id);

ALTER TABLE public.order_operation_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_operation_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read operation states"
  ON public.order_operation_states
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert operation states"
  ON public.order_operation_states
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update operation states"
  ON public.order_operation_states
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read operation files"
  ON public.order_operation_files
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert operation files"
  ON public.order_operation_files
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update operation files"
  ON public.order_operation_files
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE TRIGGER order_operation_states_updated_at
  BEFORE UPDATE ON public.order_operation_states
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER order_operation_files_updated_at
  BEFORE UPDATE ON public.order_operation_files
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();