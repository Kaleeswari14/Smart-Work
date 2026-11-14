-- ============================================================================
-- 002_rls_policies.sql
-- Row Level Security (RLS) Policies & Access Controls
-- ============================================================================

-- 1. Enable RLS on all business tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.works ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 2. Helper Functions for Role Checking
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'owner'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Profiles Policies
DROP POLICY IF EXISTS "Users can view all registered profiles" ON public.profiles;
CREATE POLICY "Users can view all registered profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Customers Policies
DROP POLICY IF EXISTS "Authenticated users can view customers" ON public.customers;
CREATE POLICY "Authenticated users can view customers"
ON public.customers FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can create customers" ON public.customers;
CREATE POLICY "Authenticated users can create customers"
ON public.customers FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update customers" ON public.customers;
CREATE POLICY "Authenticated users can update customers"
ON public.customers FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Only owners can delete customers" ON public.customers;
CREATE POLICY "Only owners can delete customers"
ON public.customers FOR DELETE
TO authenticated
USING (public.is_owner());

-- 5. Works Policies
DROP POLICY IF EXISTS "Authenticated users can view works" ON public.works;
CREATE POLICY "Authenticated users can view works"
ON public.works FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can create works" ON public.works;
CREATE POLICY "Authenticated users can create works"
ON public.works FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update works" ON public.works;
CREATE POLICY "Authenticated users can update works"
ON public.works FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Only owners can delete works" ON public.works;
CREATE POLICY "Only owners can delete works"
ON public.works FOR DELETE
TO authenticated
USING (public.is_owner());

-- 6. Work Sessions Policies
DROP POLICY IF EXISTS "Authenticated users can view work sessions" ON public.work_sessions;
CREATE POLICY "Authenticated users can view work sessions"
ON public.work_sessions FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert work sessions" ON public.work_sessions;
CREATE POLICY "Authenticated users can insert work sessions"
ON public.work_sessions FOR INSERT
TO authenticated
WITH CHECK (true);

-- 7. Payments Policies
DROP POLICY IF EXISTS "Authenticated users can view payments" ON public.payments;
CREATE POLICY "Authenticated users can view payments"
ON public.payments FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can record payments" ON public.payments;
CREATE POLICY "Authenticated users can record payments"
ON public.payments FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Only owners can delete payments" ON public.payments;
CREATE POLICY "Only owners can delete payments"
ON public.payments FOR DELETE
TO authenticated
USING (public.is_owner());

-- 8. Audit Logs Policies
DROP POLICY IF EXISTS "Authenticated users can view audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can view audit logs"
ON public.audit_logs FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can create audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can create audit logs"
ON public.audit_logs FOR INSERT
TO authenticated
WITH CHECK (true);
