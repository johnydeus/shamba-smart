-- =========================================================
-- SHAMBA SMART — model_versions table
-- Run in Supabase Dashboard → SQL Editor → New Query
-- =========================================================

DROP TABLE IF EXISTS model_versions CASCADE;

CREATE TABLE model_versions (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  version      TEXT        NOT NULL UNIQUE,        -- e.g. 'v3', 'v3.1'
  download_url TEXT        NOT NULL,               -- Supabase Storage public URL
  is_active    BOOLEAN     NOT NULL DEFAULT false, -- only one row should be true
  description  TEXT,                               -- human notes about the release
  class_count  INTEGER,                            -- number of output classes
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- Only authenticated requests can read (anon key is enough for app)
ALTER TABLE model_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_model_versions" ON model_versions;
CREATE POLICY "public_read_model_versions"
  ON model_versions FOR SELECT
  TO authenticated
  USING (true);

-- Only afisa/admin can insert or update
DROP POLICY IF EXISTS "afisa_manage_model_versions" ON model_versions;
CREATE POLICY "afisa_manage_model_versions"
  ON model_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'afisa'
    )
  );

-- Helper: when setting a new active version, clear the previous one first.
-- Run this before each new INSERT to avoid multiple active rows:
-- UPDATE model_versions SET is_active = false WHERE is_active = true;
-- INSERT INTO model_versions (version, download_url, is_active, description)
-- VALUES ('v3', 'https://...', true, 'Retrained on Tanzanian farmer photos');

-- Upload the .tflite to Supabase Storage → bucket: "mkulima-models"
-- then paste the public URL in download_url above.
