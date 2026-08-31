-- Repair installations where session scan tables were created before the
-- UNIQUE constraints in migration 008 were introduced. CREATE TABLE IF NOT
-- EXISTS does not add missing constraints to an already existing table.

-- PostgreSQL ON CONFLICT column inference works with a UNIQUE index. These
-- names intentionally match the backing indexes created by migration 008's
-- constraints, making the statements no-ops on already-correct databases.
-- No existing scan data is deleted or modified by this migration.
CREATE UNIQUE INDEX IF NOT EXISTS session_scan_reports_unique_session
  ON public.session_scan_reports(session_id);

CREATE UNIQUE INDEX IF NOT EXISTS session_scan_files_unique_session_type
  ON public.session_scan_files(session_id, file_type);
