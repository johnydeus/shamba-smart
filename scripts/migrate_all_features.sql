-- ============================================================
-- Shamba Smart — All New Features Migration
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Feature 2: Soil data enhanced columns
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS ph FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS nitrogen FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS phosphorus FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS potassium FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS organic_carbon FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS clay_pct FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS sand_pct FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS silt_pct FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS soil_score INT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS ai_recommendation TEXT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS gps_lat FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS gps_lng FLOAT;
ALTER TABLE soil_data ADD COLUMN IF NOT EXISTS fetched_at TIMESTAMPTZ DEFAULT NOW();

-- Feature 3: IPM records
CREATE TABLE IF NOT EXISTS ipm_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  farm_id UUID,
  crop_name TEXT,
  pest_observed TEXT,
  pest_count FLOAT,
  plants_affected_pct FLOAT,
  threshold_value FLOAT,
  decision TEXT,
  action_taken TEXT,
  pesticide_used TEXT,
  cost_tzs INT,
  weather_conditions TEXT,
  gps_lat FLOAT,
  gps_lng FLOAT,
  observed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 4: Fertiliser prescriptions
CREATE TABLE IF NOT EXISTS fertiliser_prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  farm_id UUID,
  crop_name TEXT,
  growth_stage TEXT,
  season TEXT,
  zone_prescriptions JSONB,
  total_cost_tzs INT,
  ai_recommendation TEXT,
  isdasoil_data JSONB,
  ndvi_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 5: Spray records
CREATE TABLE IF NOT EXISTS spray_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  farm_id UUID,
  spray_date TIMESTAMPTZ,
  pesticide_name TEXT,
  target_pest TEXT,
  dose_ml_per_15L FLOAT,
  area_sprayed_acres FLOAT,
  total_chemical_used FLOAT,
  weather_at_time JSONB,
  spray_safety_score TEXT,
  cost_tzs INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 6: IoT sensor stations
CREATE TABLE IF NOT EXISTS sensor_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  station_id TEXT UNIQUE NOT NULL,
  station_name TEXT,
  gps_lat FLOAT,
  gps_lng FLOAT,
  plot_name TEXT,
  sensors_installed TEXT[],
  subscription_tier TEXT DEFAULT 'premium',
  is_active BOOLEAN DEFAULT TRUE,
  last_ping TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 6: IoT sensor readings
CREATE TABLE IF NOT EXISTS sensor_readings (
  id BIGSERIAL PRIMARY KEY,
  station_id TEXT,
  farmer_id UUID,
  timestamp TIMESTAMPTZ NOT NULL,
  soil_moisture_pct FLOAT,
  soil_temp_c FLOAT,
  air_temp_c FLOAT,
  humidity_pct FLOAT,
  nitrogen_mg_kg FLOAT,
  phosphorus_mg_kg FLOAT,
  potassium_mg_kg FLOAT,
  soil_ph FLOAT,
  battery_pct FLOAT,
  raw_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 6: Agronomist profiles
CREATE TABLE IF NOT EXISTS agronomist_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  qualification TEXT,
  speciality TEXT,
  phone TEXT,
  email TEXT,
  region TEXT,
  assigned_farmers UUID[],
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 6: Agronomist messages
CREATE TABLE IF NOT EXISTS agronomist_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  agronomist_id UUID REFERENCES agronomist_profiles(id),
  sender_type TEXT,
  message TEXT,
  attachment_url TEXT,
  sensor_context JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 7: Price alerts
CREATE TABLE IF NOT EXISTS price_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  crop_name TEXT,
  market_name TEXT,
  target_price_tzs INT,
  alert_type TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 9: Farm events (diary)
CREATE TABLE IF NOT EXISTS farm_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  farm_id UUID,
  event_type TEXT NOT NULL,
  event_date TIMESTAMPTZ NOT NULL,
  crop_name TEXT,
  description TEXT,
  quantity FLOAT,
  quantity_unit TEXT,
  cost_tzs INT,
  zone TEXT,
  method TEXT,
  product_used TEXT,
  labour_workers INT,
  labour_cost_tzs INT,
  yield_kg FLOAT,
  revenue_tzs INT,
  notes TEXT,
  photo_url TEXT,
  gps_lat FLOAT,
  gps_lng FLOAT,
  weather_at_time JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 9: Farm seasons
CREATE TABLE IF NOT EXISTS farm_seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  farm_id UUID,
  season_name TEXT,
  crop_name TEXT,
  variety TEXT,
  start_date DATE,
  expected_harvest DATE,
  actual_harvest DATE,
  target_yield_kg FLOAT,
  actual_yield_kg FLOAT,
  total_cost_tzs INT,
  total_revenue_tzs INT,
  profit_tzs INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature 10: Greenhouse setups
CREATE TABLE IF NOT EXISTS greenhouse_setups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  structure_type TEXT,
  size_sqm FLOAT,
  crop_grown TEXT,
  construction_date DATE,
  total_investment_tzs INT,
  current_yield_kg FLOAT,
  open_field_yield_kg FLOAT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on all new tables
ALTER TABLE ipm_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE fertiliser_prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE spray_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE agronomist_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agronomist_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_seasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE greenhouse_setups ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (farmers can see their own data)
DROP POLICY IF EXISTS "farmer_ipm" ON ipm_records;
CREATE POLICY "farmer_ipm" ON ipm_records
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_fertiliser" ON fertiliser_prescriptions;
CREATE POLICY "farmer_fertiliser" ON fertiliser_prescriptions
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_spray" ON spray_records;
CREATE POLICY "farmer_spray" ON spray_records
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_stations" ON sensor_stations;
CREATE POLICY "farmer_stations" ON sensor_stations
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_readings" ON sensor_readings;
CREATE POLICY "farmer_readings" ON sensor_readings
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "all_agronomists" ON agronomist_profiles;
CREATE POLICY "all_agronomists" ON agronomist_profiles
  FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "farmer_agro_messages" ON agronomist_messages;
CREATE POLICY "farmer_agro_messages" ON agronomist_messages
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_alerts" ON price_alerts;
CREATE POLICY "farmer_alerts" ON price_alerts
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_events" ON farm_events;
CREATE POLICY "farmer_events" ON farm_events
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_seasons" ON farm_seasons;
CREATE POLICY "farmer_seasons" ON farm_seasons
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_greenhouse" ON greenhouse_setups;
CREATE POLICY "farmer_greenhouse" ON greenhouse_setups
  FOR ALL USING (farmer_id = auth.uid());

-- Seed one sample agronomist
INSERT INTO agronomist_profiles (name, qualification, speciality, region, is_available)
VALUES ('Dkt. Amani Mwalimu', 'BSc Agronomy, SUA', 'Mazao ya Nafaka na Mbogamboga', 'Morogoro', TRUE)
ON CONFLICT DO NOTHING;
