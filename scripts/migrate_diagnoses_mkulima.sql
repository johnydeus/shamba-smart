-- Migration: Add Mkulima AI v2 columns to diagnoses table
-- Run in Supabase Dashboard → SQL Editor

ALTER TABLE diagnoses
  ADD COLUMN IF NOT EXISTS disease_key    TEXT,
  ADD COLUMN IF NOT EXISTS disease_swahili TEXT,
  ADD COLUMN IF NOT EXISTS ukali          TEXT,
  ADD COLUMN IF NOT EXISTS zao            TEXT,
  ADD COLUMN IF NOT EXISTS top3           JSONB,
  ADD COLUMN IF NOT EXISTS source         TEXT DEFAULT 'mkulima_ai_v2',
  ADD COLUMN IF NOT EXISTS model_version  TEXT DEFAULT 'v2';

-- Index for filtering by disease key or crop (zao)
CREATE INDEX IF NOT EXISTS idx_diagnoses_disease_key
  ON diagnoses (disease_key);

CREATE INDEX IF NOT EXISTS idx_diagnoses_zao
  ON diagnoses (zao);
