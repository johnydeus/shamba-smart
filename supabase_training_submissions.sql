-- =========================================================
-- SHAMBA SMART — training_submissions table
-- Run in Supabase Dashboard → SQL Editor → New Query
-- =========================================================

-- Drop and recreate cleanly
DROP TABLE IF EXISTS training_submissions CASCADE;

CREATE TABLE training_submissions (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  farmer_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  disease_key   TEXT        NOT NULL,
  is_correct    BOOLEAN     NOT NULL,
  crop_name     TEXT,
  photo_url     TEXT,
  model_version TEXT        DEFAULT 'v2',
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- Farmers can insert their own submissions
ALTER TABLE training_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "farmer_insert_training" ON training_submissions;
CREATE POLICY "farmer_insert_training"
  ON training_submissions FOR INSERT
  TO authenticated
  WITH CHECK (farmer_id = auth.uid());

-- Afisa Kilimo can read all submissions for verification
DROP POLICY IF EXISTS "afisa_read_training" ON training_submissions;
CREATE POLICY "afisa_read_training"
  ON training_submissions FOR SELECT
  TO authenticated
  USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'afisa'
    )
  );

-- Index for afisa dashboard queries
CREATE INDEX IF NOT EXISTS idx_training_disease_key
  ON training_submissions (disease_key);

CREATE INDEX IF NOT EXISTS idx_training_created_at
  ON training_submissions (created_at DESC);
