ALTER TABLE public.order_operation_states
ADD COLUMN IF NOT EXISTS board_column_code TEXT NOT NULL DEFAULT 'design_waiting';

CREATE INDEX IF NOT EXISTS order_operation_states_board_column_idx
  ON public.order_operation_states(board_column_code);