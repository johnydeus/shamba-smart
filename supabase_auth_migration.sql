-- =============================================================================
-- Shamba Smart — Supabase Auth Migration
-- Run this ONCE in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- =============================================================================

-- 1. Add profile_json column to farmers table (stores full UserModel as JSON)
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS profile_json TEXT DEFAULT NULL;

-- 2. Update RLS policies
--    NOTE: PostgreSQL has no "CREATE POLICY IF NOT EXISTS".
--    We DROP each policy first (IF EXISTS is safe), then CREATE it fresh.

-- Drop any old or conflicting policies
DROP POLICY IF EXISTS "Allow all on farmers"    ON farmers;
DROP POLICY IF EXISTS "Enable all for farmers"  ON farmers;
DROP POLICY IF EXISTS "farmers_insert_own"      ON farmers;
DROP POLICY IF EXISTS "farmers_update_own"      ON farmers;
DROP POLICY IF EXISTS "farmers_select_all"      ON farmers;

-- Enable RLS (safe to run even if already enabled)
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert their own profile row
CREATE POLICY "farmers_insert_own"
  ON farmers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid()::text = id);

-- Allow authenticated users to update their own profile row
CREATE POLICY "farmers_update_own"
  ON farmers FOR UPDATE
  TO authenticated
  USING     (auth.uid()::text = id)
  WITH CHECK (auth.uid()::text = id);

-- Allow every authenticated user to read ALL farmer profiles (user directory)
CREATE POLICY "farmers_select_all"
  ON farmers FOR SELECT
  TO authenticated
  USING (true);

-- 3. Grant anon SELECT so the user directory works even when the JWT briefly lapses
GRANT SELECT ON farmers TO anon;

-- =============================================================================
-- IMPORTANT — one manual step in the Supabase Dashboard:
--   Authentication → Settings → Email Auth
--   → UNCHECK "Enable email confirmations"
-- This lets farmers log in immediately after registering without checking email.
-- (This setting cannot be changed via SQL.)
-- =============================================================================
