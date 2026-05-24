-- Run this in Supabase SQL Editor BEFORE running upload_pesticides.py
-- Adds 4 new columns needed for TPRI Excel upload

ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS registration_number TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS registrant          TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS usage_target        TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS sub_category        TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS pesticide_type      TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS is_restricted       BOOLEAN DEFAULT FALSE;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS pesticide_type_sw   TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS source              TEXT DEFAULT 'TPRI Tanzania 2011';
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS registration_year   INT   DEFAULT 2011;

-- Index for fast search
CREATE INDEX IF NOT EXISTS idx_pesticides_trade ON pesticides(LOWER(brand_name));
CREATE INDEX IF NOT EXISTS idx_pesticides_type  ON pesticides(pesticide_type);

SELECT 'Columns added successfully' AS result;
