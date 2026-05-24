-- Migration: Add detailed agronomic fields to seed_varieties table
-- Run this in Supabase SQL Editor: Dashboard -> SQL Editor -> paste & run

-- Step 0: Remove duplicate variety_name rows (keep the lowest id)
DELETE FROM seed_varieties
WHERE id NOT IN (
  SELECT MIN(id) FROM seed_varieties GROUP BY variety_name
);

-- Step 1: Add unique constraint on variety_name (safe — only if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'seed_varieties'
      AND constraint_name = 'uq_seed_varieties_name'
  ) THEN
    ALTER TABLE seed_varieties
      ADD CONSTRAINT uq_seed_varieties_name UNIQUE (variety_name);
  END IF;
END $$;

-- Step 2: Add new detailed agronomic columns
ALTER TABLE seed_varieties
  ADD COLUMN IF NOT EXISTS registration_year      INTEGER,
  ADD COLUMN IF NOT EXISTS registrant             TEXT,
  ADD COLUMN IF NOT EXISTS crop_scientific        TEXT,
  ADD COLUMN IF NOT EXISTS crop_full_name         TEXT,
  ADD COLUMN IF NOT EXISTS altitude_range         TEXT,
  ADD COLUMN IF NOT EXISTS altitude_min           INTEGER,
  ADD COLUMN IF NOT EXISTS altitude_max           INTEGER,
  ADD COLUMN IF NOT EXISTS suitable_regions       TEXT[],
  ADD COLUMN IF NOT EXISTS grain_yield            TEXT,
  ADD COLUMN IF NOT EXISTS grain_yield_min        NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS grain_yield_max        NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS distinctive_characters TEXT,
  ADD COLUMN IF NOT EXISTS days_to_tasseling      INTEGER,
  ADD COLUMN IF NOT EXISTS plant_height_cm        INTEGER,
  ADD COLUMN IF NOT EXISTS grain_size             TEXT,
  ADD COLUMN IF NOT EXISTS stem_colour            TEXT,
  ADD COLUMN IF NOT EXISTS detail_url             TEXT,
  ADD COLUMN IF NOT EXISTS additional_fields      JSONB,
  ADD COLUMN IF NOT EXISTS updated_at             TIMESTAMPTZ DEFAULT NOW();

-- Step 3: Indexes for performance
CREATE INDEX IF NOT EXISTS idx_seed_varieties_regions
  ON seed_varieties USING GIN (suitable_regions);

CREATE INDEX IF NOT EXISTS idx_seed_varieties_altitude
  ON seed_varieties (altitude_min, altitude_max);

CREATE INDEX IF NOT EXISTS idx_seed_varieties_crop_type_en
  ON seed_varieties (crop_type_en);
