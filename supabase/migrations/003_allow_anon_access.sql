-- ============================================================================
-- 003_allow_anon_access.sql
-- Work Management System - Allow Anon Role Access for Development & Testing
-- Run this in Supabase SQL Editor if you are testing before Phase 4 Auth Login
-- ============================================================================

-- 1. Customers
DROP POLICY IF EXISTS "Anon can view customers" ON public.customers;
CREATE POLICY "Anon can view customers"
ON public.customers FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "Anon can create customers" ON public.customers;
CREATE POLICY "Anon can create customers"
ON public.customers FOR INSERT
TO anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Anon can update customers" ON public.customers;
CREATE POLICY "Anon can update customers"
ON public.customers FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- 2. Works
DROP POLICY IF EXISTS "Anon can view works" ON public.works;
CREATE POLICY "Anon can view works"
ON public.works FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "Anon can create works" ON public.works;
CREATE POLICY "Anon can create works"
ON public.works FOR INSERT
TO anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Anon can update works" ON public.works;
CREATE POLICY "Anon can update works"
ON public.works FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- 3. Work Sessions
DROP POLICY IF EXISTS "Anon can view work sessions" ON public.work_sessions;
CREATE POLICY "Anon can view work sessions"
ON public.work_sessions FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "Anon can create work sessions" ON public.work_sessions;
CREATE POLICY "Anon can create work sessions"
ON public.work_sessions FOR INSERT
TO anon
WITH CHECK (true);

-- 4. Payments
DROP POLICY IF EXISTS "Anon can view payments" ON public.payments;
CREATE POLICY "Anon can view payments"
ON public.payments FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "Anon can record payments" ON public.payments;
CREATE POLICY "Anon can record payments"
ON public.payments FOR INSERT
TO anon
WITH CHECK (true);

-- 5. Audit Logs
DROP POLICY IF EXISTS "Anon can view audit logs" ON public.audit_logs;
CREATE POLICY "Anon can view audit logs"
ON public.audit_logs FOR SELECT
TO anon
USING (true);

DROP POLICY IF EXISTS "Anon can create audit logs" ON public.audit_logs;
CREATE POLICY "Anon can create audit logs"
ON public.audit_logs FOR INSERT
TO anon
WITH CHECK (true);
