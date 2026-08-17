-- The session-based analysis flow upserts by (patient_id, session_id).
-- Existing installations may have these columns without a matching UNIQUE
-- index, which makes PostgreSQL reject the ON CONFLICT specification.

-- Preserve every older duplicate before consolidating the active table. The
-- archive intentionally has RLS enabled with no client policies because its
-- JSON payload can contain clinical data.
CREATE TABLE IF NOT EXISTS public.analysis_results_duplicate_archive (
  source_id BIGINT PRIMARY KEY,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archive_reason TEXT NOT NULL,
  row_data JSONB NOT NULL
);

ALTER TABLE public.analysis_results_duplicate_archive ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.analysis_results_duplicate_archive
  FROM PUBLIC, anon, authenticated;

WITH ranked_results AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY patient_id, session_id
      ORDER BY updated_at DESC NULLS LAST,
               analysis_date DESC NULLS LAST,
               created_at DESC NULLS LAST,
               id DESC
    ) AS row_number
  FROM public.analysis_results
  WHERE patient_id IS NOT NULL
    AND session_id IS NOT NULL
)
INSERT INTO public.analysis_results_duplicate_archive (
  source_id,
  archive_reason,
  row_data
)
SELECT
  result.id,
  'Duplicate patient_id/session_id archived before unique index repair',
  TO_JSONB(result)
FROM public.analysis_results result
JOIN ranked_results ranked ON ranked.id = result.id
WHERE ranked.row_number > 1
ON CONFLICT (source_id) DO NOTHING;

WITH ranked_results AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY patient_id, session_id
      ORDER BY updated_at DESC NULLS LAST,
               analysis_date DESC NULLS LAST,
               created_at DESC NULLS LAST,
               id DESC
    ) AS row_number
  FROM public.analysis_results
  WHERE patient_id IS NOT NULL
    AND session_id IS NOT NULL
)
DELETE FROM public.analysis_results result
USING ranked_results ranked
WHERE result.id = ranked.id
  AND ranked.row_number > 1;

CREATE UNIQUE INDEX IF NOT EXISTS ux_analysis_results_patient_session_v020
  ON public.analysis_results(patient_id, session_id);

-- Also guarantee the two scan conflict targets with migration-specific names.
-- This avoids a stale, non-unique index with an older name causing an
-- IF NOT EXISTS statement to be skipped.
CREATE UNIQUE INDEX IF NOT EXISTS ux_session_scan_reports_session_v020
  ON public.session_scan_reports(session_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_session_scan_files_session_type_v020
  ON public.session_scan_files(session_id, file_type);

NOTIFY pgrst, 'reload schema';
