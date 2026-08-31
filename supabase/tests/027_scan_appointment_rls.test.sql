BEGIN;

SELECT plan(18);

SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.scan_appointment_requests',
    'INSERT'
  ),
  'anon cannot insert individual requests directly'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.scan_appointment_requests',
    'SELECT'
  ),
  'anon cannot read individual requests'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.scan_appointment_requests',
    'UPDATE'
  ),
  'anon cannot update individual requests'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.scan_appointment_requests',
    'DELETE'
  ),
  'anon cannot delete individual requests'
);

SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.corporate_scan_requests',
    'INSERT'
  ),
  'anon cannot insert corporate requests directly'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.corporate_scan_requests',
    'SELECT'
  ),
  'anon cannot read corporate requests'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.corporate_scan_requests',
    'UPDATE'
  ),
  'anon cannot update corporate requests'
);
SELECT ok(
  NOT has_table_privilege(
    'anon',
    'public.corporate_scan_requests',
    'DELETE'
  ),
  'anon cannot delete corporate requests'
);

SELECT ok(
  has_table_privilege(
    'service_role',
    'public.scan_appointment_requests',
    'INSERT, UPDATE'
  ),
  'service role can create and update individual requests'
);
SELECT ok(
  has_table_privilege(
    'service_role',
    'public.corporate_scan_requests',
    'INSERT, UPDATE'
  ),
  'service role can create and update corporate requests'
);

SELECT ok(
  (
    SELECT relrowsecurity
    FROM pg_class
    WHERE oid = 'public.scan_appointment_requests'::regclass
  ),
  'individual requests keep row level security enabled'
);
SELECT ok(
  (
    SELECT relrowsecurity
    FROM pg_class
    WHERE oid = 'public.corporate_scan_requests'::regclass
  ),
  'corporate requests keep row level security enabled'
);

SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'scan_appointment_requests'
      AND policyname = 'Optiyou team manages scan appointment requests'
      AND roles @> ARRAY['authenticated']::name[]
      AND cmd = 'ALL'
  ),
  'authenticated team policy remains on individual requests'
);
SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'corporate_scan_requests'
      AND policyname = 'Optiyou team manages corporate scan requests'
      AND roles @> ARRAY['authenticated']::name[]
      AND cmd = 'ALL'
  ),
  'authenticated team policy remains on corporate requests'
);

SELECT is(
  (
    SELECT count(*)::INTEGER
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'scan_appointment_requests'
      AND roles @> ARRAY['anon']::name[]
  ),
  0,
  'individual requests have no anon RLS policy'
);
SELECT is(
  (
    SELECT count(*)::INTEGER
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'corporate_scan_requests'
      AND roles @> ARRAY['anon']::name[]
  ),
  0,
  'corporate requests have no anon RLS policy'
);

SELECT ok(
  (
    SELECT is_nullable = 'NO'
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'scan_appointment_requests'
      AND column_name = 'client_request_id'
  ),
  'individual idempotency key is required'
);
SELECT ok(
  (
    SELECT is_nullable = 'NO'
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'corporate_scan_requests'
      AND column_name = 'client_request_id'
  ),
  'corporate idempotency key is required'
);

SELECT * FROM finish();

ROLLBACK;
