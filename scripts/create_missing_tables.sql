-- Run this in Supabase Dashboard → SQL Editor
-- Creates all missing tables for the Shamba Smart data pipeline

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

-- Ensure existing tables have all needed columns
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS phi_days INT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS registration_number TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS tphpa_registered BOOLEAN DEFAULT TRUE;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE pesticides ADD COLUMN IF NOT EXISTS scraped_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE market_prices ADD COLUMN IF NOT EXISTS crop_name_en TEXT;
ALTER TABLE market_prices ADD COLUMN IF NOT EXISTS crop_name_sw TEXT;
ALTER TABLE market_prices ADD COLUMN IF NOT EXISTS price_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE market_prices ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'kilimo.go.tz';
ALTER TABLE market_prices ADD COLUMN IF NOT EXISTS scraped_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS gps_lat FLOAT;
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS gps_lng FLOAT;
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE;
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS source TEXT;
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS scraped_at TIMESTAMPTZ DEFAULT NOW();

-- Disable RLS for pipeline tables (data is public reference data)
ALTER TABLE seed_varieties DISABLE ROW LEVEL SECURITY;
ALTER TABLE research_data DISABLE ROW LEVEL SECURITY;
ALTER TABLE fertilisers DISABLE ROW LEVEL SECURITY;
ALTER TABLE agro_products DISABLE ROW LEVEL SECURITY;
ALTER TABLE scrape_logs DISABLE ROW LEVEL SECURITY;
