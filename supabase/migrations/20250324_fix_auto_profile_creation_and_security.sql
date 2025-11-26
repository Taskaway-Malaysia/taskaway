-- Migration: Fix Auto-Profile Creation and Security Issues
-- Date: 2025-03-24
-- Purpose:
--   1. Create auto-profile trigger to prevent registration bugs
--   2. Backfill 17 missing user profiles
--   3. Fix critical security vulnerabilities

-- ============================================================================
-- PART 1: AUTO-PROFILE CREATION TRIGGER
-- ============================================================================
-- This fixes TASK-187: Registration flow where users get "invalid verification code"
-- Root cause: 35% of users have auth accounts but no profiles

-- Create function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert new profile for the user (only id, created_at, updated_at)
  INSERT INTO public.taskaway_profiles (
    id,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Profile already exists, ignore
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log error but don't block user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Add comment for documentation
COMMENT ON FUNCTION public.handle_new_user() IS
'Automatically creates a profile in taskaway_profiles when a new user signs up in auth.users';

-- ============================================================================
-- PART 2: BACKFILL MISSING PROFILES
-- ============================================================================
-- Backfill profiles for 17 users who registered before trigger was created

INSERT INTO public.taskaway_profiles (id, created_at, updated_at)
SELECT
  au.id,
  au.created_at,
  NOW() as updated_at
FROM auth.users au
LEFT JOIN public.taskaway_profiles tp ON au.id = tp.id
WHERE tp.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Verify backfill
-- Expected: ~17 rows inserted
DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM auth.users au
  LEFT JOIN public.taskaway_profiles tp ON au.id = tp.id
  WHERE tp.id IS NULL;

  IF missing_count > 0 THEN
    RAISE WARNING 'Still have % users without profiles after backfill', missing_count;
  ELSE
    RAISE NOTICE 'All users now have profiles - backfill successful';
  END IF;
END $$;

-- ============================================================================
-- PART 3: FIX SECURITY VULNERABILITIES
-- ============================================================================

-- 3.1 Remove insecure public.user_emails view
-- This view exposes auth.users to anonymous users (HIGH RISK)
DROP VIEW IF EXISTS public.user_emails CASCADE;

-- 3.2 Fix taskaway_payments table (RLS disabled - HIGH RISK)
-- Enable RLS on payments table
ALTER TABLE public.taskaway_payments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own payments" ON public.taskaway_payments;
DROP POLICY IF EXISTS "Users can insert own payments" ON public.taskaway_payments;
DROP POLICY IF EXISTS "Service role full access" ON public.taskaway_payments;

-- Create RLS policies for payments (using payer_id and payee_id columns)
CREATE POLICY "Users can view own payments"
  ON public.taskaway_payments
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = payer_id OR
    auth.uid() = payee_id
  );

CREATE POLICY "Users can insert own payments"
  ON public.taskaway_payments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = payer_id OR
    auth.uid() = payee_id
  );

CREATE POLICY "Service role full access"
  ON public.taskaway_payments
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 3.3 Fix taskaway_cards table (RLS enabled but no policies)
DROP POLICY IF EXISTS "Users can view own cards" ON public.taskaway_cards;
DROP POLICY IF EXISTS "Users can manage own cards" ON public.taskaway_cards;

CREATE POLICY "Users can view own cards"
  ON public.taskaway_cards
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own cards"
  ON public.taskaway_cards
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 3.4 Fix taskaway_stripe_account table (RLS enabled but no policies)
DROP POLICY IF EXISTS "Users can view own stripe account" ON public.taskaway_stripe_account;
DROP POLICY IF EXISTS "Users can manage own stripe account" ON public.taskaway_stripe_account;

CREATE POLICY "Users can view own stripe account"
  ON public.taskaway_stripe_account
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own stripe account"
  ON public.taskaway_stripe_account
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check trigger exists
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
  AND event_object_schema = 'auth';

-- Check all users have profiles
SELECT
  COUNT(DISTINCT au.id) as total_auth_users,
  COUNT(DISTINCT tp.id) as total_profiles,
  COUNT(DISTINCT au.id) - COUNT(DISTINCT tp.id) as missing_profiles
FROM auth.users au
LEFT JOIN public.taskaway_profiles tp ON au.id = tp.id;

-- Check RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('taskaway_payments', 'taskaway_cards', 'taskaway_stripe_account')
ORDER BY tablename, policyname;

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user();
