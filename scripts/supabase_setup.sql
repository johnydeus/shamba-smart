-- ================================================================
-- SHAMBA SMART — Run this in Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste → Run
-- ================================================================

-- 1. Fix RLS policies to allow pipeline inserts
ALTER TABLE market_prices DISABLE ROW LEVEL SECURITY;
ALTER TABLE pesticides    DISABLE ROW LEVEL SECURITY;
ALTER TABLE agrovets      DISABLE ROW LEVEL SECURITY;

-- 2. Add missing columns to agrovets
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS source TEXT;

-- 3. Create missing pipeline tables
CREATE TABLE IF NOT EXISTS seed_varieties (
  id SERIAL PRIMARY KEY,
  variety_name TEXT NOT NULL,
  crop_type_en TEXT,
  crop_type_sw TEXT,
  maturity_days INT,
  yield_kg_per_acre FLOAT,
  recommended_regions TEXT[],
  breeder TEXT,
  tosci_certified BOOLEAN DEFAULT TRUE,
  drought_tolerant BOOLEAN,
  disease_resistant TEXT[],
  source_url TEXT,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE seed_varieties DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS research_data (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  data_type TEXT,
  crop_name TEXT,
  pest_or_disease TEXT,
  recommendation TEXT,
  source TEXT DEFAULT 'TPRI',
  source_url TEXT,
  published_date DATE,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE research_data DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS fertilisers (
  id SERIAL PRIMARY KEY,
  product_name TEXT NOT NULL,
  nitrogen_pct FLOAT,
  phosphorus_pct FLOAT,
  potassium_pct FLOAT,
  npk_ratio TEXT,
  recommended_crops TEXT[],
  application_rate TEXT,
  supplier TEXT,
  price_tzs INT,
  source_url TEXT,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE fertilisers DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS agro_products (
  id SERIAL PRIMARY KEY,
  product_name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  target_crops TEXT[],
  supplier TEXT,
  price_tzs INT,
  source_url TEXT,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE agro_products DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS scrape_logs (
  id SERIAL PRIMARY KEY,
  target_name TEXT NOT NULL,
  target_url TEXT,
  records_scraped INT DEFAULT 0,
  status TEXT,
  error_message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
ALTER TABLE scrape_logs DISABLE ROW LEVEL SECURITY;

-- 4. Grant anon access to all pipeline tables
GRANT ALL ON pesticides    TO anon;
GRANT ALL ON market_prices TO anon;
GRANT ALL ON agrovets      TO anon;
GRANT ALL ON seed_varieties TO anon;
GRANT ALL ON research_data  TO anon;
GRANT ALL ON fertilisers    TO anon;
GRANT ALL ON agro_products  TO anon;
GRANT ALL ON scrape_logs    TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Done!
SELECT 'Setup complete' AS status;
