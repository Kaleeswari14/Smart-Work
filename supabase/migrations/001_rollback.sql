-- ============================================================================
-- 001_rollback.sql
-- Rollback Script for Work Management Database
-- ============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP TRIGGER IF EXISTS trigger_works_updated_at ON public.works;
DROP TRIGGER IF EXISTS trigger_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
DROP FUNCTION IF EXISTS public.handle_updated_at();
DROP FUNCTION IF EXISTS public.is_owner();

DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.work_sessions CASCADE;
DROP TABLE IF EXISTS public.works CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
