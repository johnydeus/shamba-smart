-- =========================================================
-- SHAMBA SMART — Supabase SQL Migrations (CLEAN RESET)
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- This drops and recreates all tables cleanly.
-- =========================================================

-- ── STEP 1: DROP OLD TABLES (reverse dependency order) ───

DROP TABLE IF EXISTS irrigation_plans CASCADE;
DROP TABLE IF EXISTS diagnoses CASCADE;
DROP TABLE IF EXISTS farms CASCADE;
DROP TABLE IF EXISTS farmers CASCADE;
DROP TABLE IF EXISTS pesticides CASCADE;
DROP TABLE IF EXISTS agrovets CASCADE;
DROP TABLE IF EXISTS market_prices CASCADE;
DROP TABLE IF EXISTS soil_data CASCADE;
DROP TABLE IF EXISTS crops CASCADE;
DROP TABLE IF EXISTS diseases CASCADE;
DROP TABLE IF EXISTS weather_cache CASCADE;

-- ── STEP 2: CREATE TABLES (fresh, correct schema) ────────

CREATE TABLE farms (
  id TEXT PRIMARY KEY,
  farmer_id TEXT NOT NULL,
  name TEXT NOT NULL,
  gps_lat FLOAT,
  gps_lng FLOAT,
  acres FLOAT DEFAULT 1.0,
  crops TEXT[] DEFAULT '{}',
  soil_type TEXT,
  region TEXT DEFAULT 'Morogoro',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE farmers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  region TEXT DEFAULT 'Morogoro',
  district TEXT,
  gps_lat FLOAT,
  gps_lng FLOAT,
  farm_acres FLOAT DEFAULT 1.0,
  soil_type TEXT,
  subscription TEXT DEFAULT 'free',
  language TEXT DEFAULT 'sw',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE diagnoses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL,
  crop_name TEXT NOT NULL,
  disease_name_en TEXT,
  disease_name_sw TEXT,
  confidence FLOAT,
  severity TEXT,
  photo_url TEXT,
  claude_response JSONB,
  soil_context JSONB,
  weather_context JSONB,
  gps_lat FLOAT,
  gps_lng FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pesticides (
  id SERIAL PRIMARY KEY,
  brand_name TEXT NOT NULL,
  active_ingredient TEXT,
  category TEXT DEFAULT 'Insecticide',
  target_disease TEXT,
  target_pests TEXT,
  target_crop TEXT,
  target_crops TEXT,
  dose_per_15l TEXT,
  ml_per_15L FLOAT,
  phi_days INT,
  price_tzs INT,
  price_range_tzs TEXT,
  tpri_registered BOOLEAN DEFAULT TRUE,
  available_regions TEXT[],
  manufacturer TEXT,
  description_sw TEXT,
  safety_sw TEXT
);

CREATE TABLE agrovets (
  id SERIAL PRIMARY KEY,
  shop_name TEXT NOT NULL,
  region TEXT NOT NULL,
  district TEXT,
  area TEXT,
  gps_lat FLOAT NOT NULL DEFAULT 0,
  gps_lng FLOAT NOT NULL DEFAULT 0,
  phone TEXT,
  products TEXT,
  opening_hours TEXT,
  verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  crop_name TEXT NOT NULL,
  market_name TEXT NOT NULL,
  price_tzs_kg INT NOT NULL,
  trend TEXT DEFAULT 'imara',
  source TEXT DEFAULT 'Wizara ya Kilimo',
  price_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE soil_data (
  id SERIAL PRIMARY KEY,
  gps_lat FLOAT NOT NULL,
  gps_lng FLOAT NOT NULL,
  ph FLOAT,
  nitrogen FLOAT,
  phosphorus FLOAT,
  potassium FLOAT,
  texture TEXT,
  source TEXT DEFAULT 'iSDAsoil',
  fetched_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  crop_name_en TEXT NOT NULL,
  crop_name_sw TEXT,
  min_temp FLOAT,
  max_temp FLOAT,
  min_rainfall FLOAT,
  max_rainfall FLOAT,
  min_ph FLOAT,
  max_ph FLOAT,
  growing_days INT,
  suitable_regions TEXT[],
  source TEXT DEFAULT 'ECOCROP'
);

CREATE TABLE diseases (
  id SERIAL PRIMARY KEY,
  disease_name_en TEXT NOT NULL,
  disease_name_sw TEXT,
  affected_crop TEXT,
  symptoms_sw TEXT,
  severity_level TEXT,
  source TEXT DEFAULT 'PlantVillage'
);

CREATE TABLE weather_cache (
  id SERIAL PRIMARY KEY,
  gps_lat FLOAT NOT NULL,
  gps_lng FLOAT NOT NULL,
  temperature FLOAT,
  humidity FLOAT,
  wind_speed FLOAT,
  rain_probability FLOAT,
  safe_to_spray BOOLEAN,
  fetched_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE irrigation_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL,
  crop_name TEXT,
  growth_stage TEXT,
  soil_type TEXT,
  farm_acres FLOAT,
  method TEXT DEFAULT 'sprinkler',
  daily_litres FLOAT,
  schedule_json JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── STEP 3: ROW LEVEL SECURITY ────────────────────────────

ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE pesticides ENABLE ROW LEVEL SECURITY;
ALTER TABLE agrovets ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
ALTER TABLE diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE irrigation_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farms_insert" ON farms FOR INSERT WITH CHECK (true);
CREATE POLICY "farms_select" ON farms FOR SELECT USING (true);
CREATE POLICY "farms_update" ON farms FOR UPDATE USING (true);
CREATE POLICY "farms_delete" ON farms FOR DELETE USING (true);

CREATE POLICY "farmers_insert" ON farmers FOR INSERT WITH CHECK (true);
CREATE POLICY "farmers_select" ON farmers FOR SELECT USING (true);
CREATE POLICY "farmers_update" ON farmers FOR UPDATE USING (true);

CREATE POLICY "diagnoses_insert" ON diagnoses FOR INSERT WITH CHECK (true);
CREATE POLICY "diagnoses_select" ON diagnoses FOR SELECT USING (true);

CREATE POLICY "pesticides_select" ON pesticides FOR SELECT USING (true);
CREATE POLICY "agrovets_select" ON agrovets FOR SELECT USING (true);
CREATE POLICY "market_prices_select" ON market_prices FOR SELECT USING (true);
CREATE POLICY "crops_select" ON crops FOR SELECT USING (true);
CREATE POLICY "diseases_select" ON diseases FOR SELECT USING (true);

CREATE POLICY "soil_data_insert" ON soil_data FOR INSERT WITH CHECK (true);
CREATE POLICY "soil_data_select" ON soil_data FOR SELECT USING (true);

CREATE POLICY "weather_cache_insert" ON weather_cache FOR INSERT WITH CHECK (true);
CREATE POLICY "weather_cache_select" ON weather_cache FOR SELECT USING (true);

CREATE POLICY "irrigation_plans_insert" ON irrigation_plans FOR INSERT WITH CHECK (true);
CREATE POLICY "irrigation_plans_select" ON irrigation_plans FOR SELECT USING (true);

-- ── STEP 4: SEED DATA — PESTICIDES ───────────────────────

INSERT INTO pesticides (brand_name, active_ingredient, category, target_pests, target_crops, dose_per_15l, phi_days, price_range_tzs, tpri_registered, manufacturer, description_sw, safety_sw) VALUES
('Coragen 20SC', 'Chlorantraniliprole 200g/L', 'Insecticide', 'Fall Armyworm, Stem borers, Leaf miners', 'Mahindi, Mpunga, Nyanya, Pamba', '20 ml', 14, '18,000–25,000 kwa lita 1', true, 'FMC Corporation', 'Dawa bora ya kuua viwavi vya jeshi na wadudu wanaochimba shina la mahindi. Inafanya kazi ndani ya mmea (systemic).', 'Vaa glovu, barakoa na miwani wakati wa kupulizia.'),
('Emamectin Benzoate 5SG', 'Emamectin benzoate 5%', 'Insecticide', 'Fall Armyworm, Diamondback moth, Thrips', 'Mahindi, Kabichi, Nyanya, Pilipili', '10 g', 7, '8,000–12,000 kwa 100g', true, 'Generic', 'Dawa ya unga inayofanya kazi haraka dhidi ya viwavi. Ni nafuu na inapatikana madukani mengi Tanzania.', 'Sumu kali — vaa PPE kamili. Usiruhusu watoto karibu na dawa.'),
('Duduthrin 15EC', 'Lambda-cyhalothrin 15g/L', 'Insecticide', 'Aphids, Whitefly, Thrips, Beetles, Armyworm', 'Mahindi, Nyanya, Maharagwe, Vitunguu, Pamba', '15 ml', 7, '5,000–8,000 kwa lita 1', true, 'Twiga Chemicals', 'Dawa rahisi inayoua wadudu wengi kwa bei nafuu. Inafaa kwa wakulima wadogo.', 'Sumu ya wastani — vaa glovu na barakoa.'),
('Karate Zeon 50CS', 'Lambda-cyhalothrin 50g/L', 'Insecticide', 'Aphids, Whitefly, Locusts, Stem borers', 'Mazao mengi', '10 ml', 7, '12,000–18,000 kwa lita 1', true, 'Syngenta', 'Dawa yenye nguvu inayofanya kazi haraka. Inafaa kwa milipuko ya nzige na viwavi.', 'Hatari kwa nyuki — usipulizie wakati wa maua.'),
('Actara 25WG', 'Thiamethoxam 25%', 'Insecticide', 'Whitefly, Aphids, Thrips, Leafhoppers', 'Nyanya, Pilipili, Vitunguu, Mahindi', '3 g', 14, '15,000–22,000 kwa 100g', true, 'Syngenta', 'Dawa ya neonicotinoid inayofanya kazi ndani ya mmea. Inaua wadudu kwa muda mrefu.', 'Hatari sana kwa nyuki — usitumie wakati wa maua.'),
('Dimethoate 40EC', 'Dimethoate 400g/L', 'Insecticide', 'Aphids, Mites, Leaf miners, Thrips', 'Nyanya, Maharagwe, Vitunguu, Pilipili', '20 ml', 10, '4,000–7,000 kwa lita 1', true, 'Generic', 'Dawa ya zamani lakini bado inafanya kazi vizuri dhidi ya wadudu wadogo kama aphids na mites.', 'Sumu kali — vaa PPE kamili. Usitumie siku 10 kabla ya kuvuna.'),
('Chlorpyrifos 480EC', 'Chlorpyrifos 480g/L', 'Insecticide', 'Stem borers, Cutworms, Termites, Soil pests', 'Mahindi, Mpunga, Pamba, Viazi', '30 ml', 21, '5,000–8,000 kwa lita 1', true, 'Generic', 'Dawa ya udongo inayoua wadudu wanaochimba. Inafaa kwa wadudu wa ardhini.', 'Sumu kali — vaa PPE kamili. Usitumie karibu na mito au maziwa.'),
('Imidacloprid 200SL', 'Imidacloprid 200g/L', 'Insecticide', 'Aphids, Whitefly, Thrips, Leafhoppers', 'Nyanya, Pilipili, Kabichi, Mbogamboga', '5 ml', 21, '8,000–14,000 kwa lita 1', true, 'Bayer CropScience', 'Dawa ya systemic inayofanya kazi kwa muda mrefu. Inaingia ndani ya mmea.', 'Hatari kwa nyuki — usitumie wakati wa kuchanua.'),
('Mancozeb 80WP', 'Mancozeb 80%', 'Fungicide', 'Early Blight, Late Blight, Anthracnose, Rust', 'Nyanya, Mahindi, Maharagwe, Vitunguu, Karoti', '40 g', 7, '5,000–8,000 kwa kg 1', true, 'Generic', 'Dawa ya unga ya kawaida inayozuia magonjwa ya ukungu. Nafuu na inapatikana kila mahali.', 'Epuka kupumua unga wakati wa kuchanganya. Vaa barakoa.'),
('Ridomil Gold MZ 68WP', 'Metalaxyl-M 4% + Mancozeb 64%', 'Fungicide', 'Late Blight, Downy Mildew, Damping off', 'Nyanya, Pilipili, Viazi, Alizeti', '30 g', 7, '12,000–18,000 kwa kg 1', true, 'Syngenta', 'Dawa bora dhidi ya ugonjwa wa kuoza nyanya (Late Blight). Inafanya kazi ndani na nje ya mmea.', 'Vaa glovu na barakoa. Hifadhi mbali na chakula na maji.'),
('Score 250EC', 'Difenoconazole 250g/L', 'Fungicide', 'Powdery Mildew, Rust, Anthracnose, Leaf Spot', 'Nyanya, Maharagwe, Vitunguu, Mahindi', '5 ml', 14, '18,000–25,000 kwa lita 1', true, 'Syngenta', 'Dawa ya nguvu inayotibu na kuzuia magonjwa ya ukungu. Kidogo tu kinatosha.', 'Vaa PPE kamili. Hifadhi mahali pa baridi na kavu.'),
('Copper Oxychloride 50WP', 'Copper oxychloride 50%', 'Fungicide', 'Bacterial Blight, Downy Mildew, Anthracnose', 'Nyanya, Pilipili, Maharagwe, Kahawa', '35 g', 7, '4,000–6,000 kwa kg 1', true, 'Generic', 'Dawa ya asili ya shaba inayofanya kazi dhidi ya magonjwa ya kuvu na bacteria.', 'Salama ya wastani — vaa glovu na barakoa tu.'),
('Carbendazim 50WP', 'Carbendazim 50%', 'Fungicide', 'Powdery Mildew, Fusarium Wilt, Grey Mould', 'Nyanya, Maharagwe, Vitunguu, Alizeti', '20 g', 14, '6,000–10,000 kwa kg 1', true, 'Generic', 'Dawa ya systemic inayoua ukungu ndani ya mmea. Inafaa kwa magonjwa ya wilting.', 'Vaa barakoa na glovu. Usitumie mara kwa mara — sugu inaweza kutokea.'),
('Trifloxystrobin 50WG', 'Trifloxystrobin 50%', 'Fungicide', 'Rust, Powdery Mildew, Leaf Blight', 'Kahawa, Mahindi, Nyanya, Vitunguu', '8 g', 21, '20,000–30,000 kwa kg 1', true, 'Bayer CropScience', 'Dawa ya strobilurin inayodumu muda mrefu. Inauzuia ukungu kuingia kwenye mmea.', 'Vaa PPE kamili. Badilisha aina ya dawa ili kuzuia sugu.'),
('Propiconazole 250EC', 'Propiconazole 250g/L', 'Fungicide', 'Rust, Leaf Spot, Grey Leaf Spot, Anthracnose', 'Mahindi, Ngano, Vitunguu', '15 ml', 14, '12,000–18,000 kwa lita 1', true, 'Generic', 'Dawa ya triazole inayozuia magonjwa ya ukungu kwenye mazao makuu.', 'Vaa PPE kamili wakati wa kupulizia.'),
('Roundup 480SL', 'Glyphosate 480g/L', 'Herbicide', 'Magugu yote (non-selective)', 'Kutumika kabla ya kupanda', '150 ml', 7, '8,000–12,000 kwa lita 1', true, 'Bayer/Monsanto', 'Dawa ya kuua magugu yote. Tumia KABLA ya kupanda mbegu.', 'Vaa glovu na buti. Usipulizie karibu na maji au mazao yanayokua.'),
('Weedmaster 720SL', '2,4-D Amine 720g/L', 'Herbicide', 'Broadleaf weeds', 'Mahindi (baada ya wiki 3)', '25 ml', 30, '5,000–8,000 kwa lita 1', true, 'Generic', 'Inaua magugu ya majani mapana bila kudhuru mahindi.', 'Sumu — usinyunyizie karibu na miti ya matunda. Vaa PPE kamili.'),
('Stomp 330E', 'Pendimethalin 330g/L', 'Herbicide', 'Pre-emergence weeds (grasses + broadleaf)', 'Mahindi, Pamba, Alizeti, Vitunguu', '120 ml', 0, '10,000–15,000 kwa lita 1', true, 'BASF', 'Piga baada ya kupanda lakini KABLA magugu hajaota. Inazuia mbegu za magugu kuota.', 'Vaa glovu na buti za mpira.'),
('Dual Gold 960EC', 'S-Metolachlor 960g/L', 'Herbicide', 'Grasses and narrow-leaf weeds', 'Mahindi, Maharagwe, Alizeti', '35 ml', 0, '12,000–18,000 kwa lita 1', true, 'Syngenta', 'Dawa ya pre-emergence inayodhibiti nyasi na magugu. Tumia baada ya kupanda kabla ya mvua.', 'Vaa PPE kamili. Hifadhi mbali na jua moja kwa moja.'),
('Dipel DF', 'Bacillus thuringiensis kurstaki 54%', 'Biopesticide', 'Fall Armyworm, Cabbage worm, Diamondback moth', 'Mahindi, Kabichi, Nyanya, Mbogamboga', '18 g', 0, '8,000–12,000 kwa 500g', true, 'Sumitomo Chemical', 'Dawa ya asili salama kabisa kwa binadamu. Inaua viwavi peke yake. Inafaa kwa kilimo hai.', 'Salama sana — hata bila PPE. Vaa barakoa kuzuia vumbi.'),
('Neem Azal T/S', 'Azadirachtin 1%', 'Biopesticide', 'Aphids, Whitefly, Thrips, Mites', 'Nyanya, Kabichi, Vitunguu, Mbogamboga', '20 ml', 3, '10,000–15,000 kwa lita 1', true, 'BioControl', 'Dawa inayotokana na mti wa mwarobaini. Salama kwa afya na mazingira.', 'Salama sana. Vaa glovu tu.'),
('Beauveria bassiana WP', 'Beauveria bassiana 1x10^8 spores/g', 'Biopesticide', 'Stem borers, Whitefly, Aphids, Thrips', 'Mahindi, Kahawa, Pamba, Mbogamboga', '40 g', 0, '12,000–18,000 kwa kg 1', true, 'TARI/BioControl', 'Kuvu wa asili unaoshambulia na kuua wadudu. Salama kabisa. Inafaa kwa kilimo hai.', 'Salama kabisa — tumia bila wasiwasi.'),
('Trichoderma viride WP', 'Trichoderma viride 2x10^6 cfu/g', 'Biopesticide', 'Damping off, Root rot, Fusarium wilt', 'Mbogamboga zote, Mahindi, Nyanya', '30 g', 0, '8,000–14,000 kwa kg 1', true, 'TARI Selian', 'Kuvu wa manufaa anayezuia magonjwa ya udongo. Tumia wakati wa kupanda.', 'Salama kabisa kwa binadamu na mazingira.'),
('Spintor 480SC', 'Spinosad 480g/L', 'Biopesticide', 'Fall Armyworm, Thrips, Leafminers', 'Mahindi, Nyanya, Kabichi, Vitunguu', '12 ml', 7, '20,000–28,000 kwa lita 1', true, 'Corteva Agriscience', 'Dawa ya asili yenye nguvu sana dhidi ya viwavi. Inatokana na bakteria wa udongo.', 'Hatari kwa nyuki — usipulizie wakati wa maua.'),
('Abamectin 18EC', 'Abamectin 18g/L', 'Biopesticide', 'Spider mites, Leaf miners, Thrips', 'Nyanya, Pilipili, Vitunguu, Parachichi', '8 ml', 7, '12,000–18,000 kwa lita 1', true, 'Syngenta', 'Dawa ya asili inayofanya kazi haraka dhidi ya utitiri na wadudu wadogo.', 'Sumu ya wastani — vaa glovu na barakoa.');

-- ── STEP 5: SEED DATA — MARKET PRICES ────────────────────

INSERT INTO market_prices (crop_name, market_name, price_tzs_kg, trend, source, price_date) VALUES
('Mahindi', 'Kariakoo — Dar es Salaam', 480, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mahindi', 'Arusha Central Market', 420, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mahindi', 'Mbeya Market', 380, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mahindi', 'Morogoro Market', 410, 'inashuka', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mahindi', 'Dodoma Market', 390, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mahindi', 'Mwanza Market', 460, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Kariakoo — Dar es Salaam', 1200, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Arusha Central Market', 900, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Mbeya Market', 800, 'inashuka', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Morogoro Market', 1000, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Dodoma Market', 950, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Nyanya', 'Mwanza Market', 1100, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Maharagwe', 'Kariakoo — Dar es Salaam', 2200, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Maharagwe', 'Arusha Central Market', 1900, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Maharagwe', 'Mbeya Market', 1700, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Maharagwe', 'Morogoro Market', 2000, 'inashuka', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mchele', 'Kariakoo — Dar es Salaam', 1800, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mchele', 'Arusha Central Market', 1600, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mchele', 'Mbeya Market', 1500, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mchele', 'Morogoro Market', 1650, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Mchele', 'Mwanza Market', 1750, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Ndizi', 'Kariakoo — Dar es Salaam', 600, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Ndizi', 'Arusha Central Market', 500, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Ndizi', 'Mbeya Market', 450, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Ndizi', 'Morogoro Market', 550, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Muhogo', 'Kariakoo — Dar es Salaam', 350, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Muhogo', 'Arusha Central Market', 300, 'inashuka', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Muhogo', 'Mbeya Market', 280, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Muhogo', 'Dodoma Market', 320, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Pilipili hoho', 'Kariakoo — Dar es Salaam', 2500, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Pilipili hoho', 'Arusha Central Market', 2200, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Pilipili hoho', 'Morogoro Market', 2000, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Pamba', 'Mbeya Market', 1200, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Pamba', 'Dodoma Market', 1100, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Alizeti', 'Dodoma Market', 1400, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Alizeti', 'Mbeya Market', 1300, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Vitunguu', 'Kariakoo — Dar es Salaam', 1800, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Vitunguu', 'Arusha Central Market', 1600, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Vitunguu', 'Dodoma Market', 1500, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Viazi vitamu', 'Kariakoo — Dar es Salaam', 700, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Viazi vitamu', 'Mbeya Market', 550, 'inashuka', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Karoti', 'Arusha Central Market', 1200, 'imara', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE),
('Karoti', 'Kariakoo — Dar es Salaam', 1400, 'inapanda', 'Wizara ya Kilimo / TanTrade', CURRENT_DATE);

-- ── STEP 6: SEED DATA — CROPS (ECOCROP) ──────────────────

INSERT INTO crops (crop_name_en, crop_name_sw, min_temp, max_temp, min_rainfall, max_rainfall, min_ph, max_ph, growing_days, suitable_regions, source) VALUES
('Maize', 'Mahindi', 10, 40, 400, 1800, 5.5, 7.5, 90, ARRAY['Morogoro','Dodoma','Arusha','Kilimanjaro','Mbeya','Iringa','Tabora','Shinyanga'], 'ECOCROP'),
('Tomato', 'Nyanya', 15, 35, 600, 1200, 5.5, 7.0, 75, ARRAY['Arusha','Kilimanjaro','Morogoro','Iringa','Tanga','Pwani'], 'ECOCROP'),
('Common Bean', 'Maharagwe', 10, 32, 300, 1500, 5.5, 7.0, 80, ARRAY['Arusha','Kilimanjaro','Mbeya','Iringa','Morogoro','Dodoma'], 'ECOCROP'),
('Pepper', 'Pilipili hoho', 18, 35, 600, 1500, 5.5, 7.0, 90, ARRAY['Arusha','Kilimanjaro','Morogoro','Pwani','Tanga'], 'ECOCROP'),
('Banana', 'Ndizi', 15, 38, 1000, 2500, 5.5, 7.0, 300, ARRAY['Kagera','Kilimanjaro','Arusha','Mbeya','Kigoma','Morogoro'], 'ECOCROP'),
('Rice', 'Mchele', 20, 40, 800, 2000, 5.0, 7.0, 120, ARRAY['Morogoro','Mbeya','Shinyanga','Mwanza','Kagera','Pwani'], 'ECOCROP'),
('Cassava', 'Muhogo', 20, 40, 500, 2000, 4.5, 7.0, 270, ARRAY['Pwani','Morogoro','Mtwara','Lindi','Dar es Salaam','Tabora'], 'ECOCROP'),
('Cotton', 'Pamba', 20, 42, 500, 1500, 5.8, 8.0, 170, ARRAY['Mwanza','Shinyanga','Tabora','Singida','Dodoma'], 'ECOCROP'),
('Sunflower', 'Alizeti', 15, 38, 400, 1200, 6.0, 7.5, 100, ARRAY['Dodoma','Singida','Manyara','Tabora','Arusha'], 'ECOCROP'),
('Sorghum', 'Mtama', 12, 42, 300, 1000, 5.5, 7.5, 110, ARRAY['Dodoma','Singida','Shinyanga','Tabora','Mwanza'], 'ECOCROP'),
('Pearl Millet', 'Uwele', 20, 42, 250, 900, 5.0, 7.0, 90, ARRAY['Dodoma','Singida','Tabora','Shinyanga'], 'ECOCROP'),
('Sweet Potato', 'Viazi vitamu', 15, 35, 500, 1500, 5.5, 7.0, 120, ARRAY['Morogoro','Mbeya','Iringa','Kagera','Kigoma'], 'ECOCROP');

-- ── STEP 7: SEED DATA — DISEASES (PlantVillage) ──────────

INSERT INTO diseases (disease_name_en, disease_name_sw, affected_crop, symptoms_sw, severity_level, source) VALUES
('Fall Armyworm', 'Viwavi wa Jeshi', 'Mahindi', 'Mashimo kwenye majani, kinyesi cha kijani kwenye kilele, shina linalochomekwa usiku', 'Kali', 'PlantVillage'),
('Late Blight', 'Ugonjwa wa Kuoza Mapema', 'Nyanya, Viazi', 'Madoa ya maji ya rangi ya kahawia kwenye majani, kuoza kwa haraka ukiwa na unyevu', 'Kali Sana', 'PlantVillage'),
('Early Blight', 'Ugonjwa wa Madoa ya Kahawia', 'Nyanya', 'Madoa ya kahawia yenye mviringo wa njano kwenye majani ya chini', 'Wastani', 'PlantVillage'),
('Maize Lethal Necrosis', 'Kufa kwa Mahindi (MLN)', 'Mahindi', 'Majani kugeuka njano na kukauka kuanzia ncha hadi shina, mimea mingi kufa pamoja', 'Kali Sana', 'PlantVillage'),
('Cassava Mosaic Disease', 'Ugonjwa wa Mosaic wa Muhogo', 'Muhogo', 'Majani yenye madoa ya njano na kijani yaliyochanganyika, ukuaji kudumaa', 'Kali', 'PlantVillage'),
('Cassava Brown Streak', 'Ugonjwa wa Kupiga Kahawia Muhogo', 'Muhogo', 'Mistari ya kahawia kwenye shina, kuoza kwa mizizi ndani yenye rangi ya njano-kahawia', 'Kali Sana', 'PlantVillage'),
('Bean Common Mosaic', 'Mosaic ya Maharagwe', 'Maharagwe', 'Majani yenye madoa ya njano na kijani, ukuaji kudumaa, majani kujikunja', 'Wastani', 'PlantVillage'),
('Bacterial Wilt', 'Ugonjwa wa Kunyauka kwa Bakteria', 'Nyanya, Pilipili', 'Mmea kunyauka ghafla hasa mchana, shina likikatwa linatoa uji mzito mzito', 'Kali Sana', 'PlantVillage'),
('Fusarium Wilt', 'Ugonjwa wa Fusarium', 'Nyanya, Maharagwe, Pilipili', 'Majani ya mmoja kunyauka kabla ya pande zote, shina likikatwa gamba la ndani ni kahawia', 'Kali', 'PlantVillage'),
('Gray Leaf Spot', 'Madoa ya Kijivu', 'Mahindi', 'Madoa marefu ya kijivu kwenye majani yanayofuata mishipa, ukungu wa kijivu upande wa chini', 'Wastani', 'PlantVillage'),
('Northern Corn Leaf Blight', 'Ugonjwa wa Blight ya Majani ya Mahindi', 'Mahindi', 'Madoa marefu ya kijivu-kijani yanayogeuka kahawia, yanafuata mstari wa jani', 'Wastani', 'PlantVillage'),
('Bean Rust', 'Kutu ya Maharagwe', 'Maharagwe', 'Vifurushi vidogo vya kahawia-nyekundu upande wa chini wa jani, majani kugeuka njano', 'Wastani', 'PlantVillage'),
('Powdery Mildew', 'Ugonjwa wa Unga Mweupe', 'Nyanya, Maharagwe, Vitunguu, Pilipili', 'Unga mweupe kwenye uso wa jani na shina, majani kugeuka njano na kuanguka', 'Wastani', 'PlantVillage'),
('Anthracnose', 'Ugonjwa wa Madoa Meusi', 'Maharagwe, Nyanya, Ndizi, Mahindi', 'Madoa meusi yenye pembeni ya njano kwenye matunda na majani, kuoza kwa matunda', 'Wastani', 'PlantVillage'),
('Damping Off', 'Kuoza kwa Miche Chini', 'Nyanya, Kabichi, Mbogamboga', 'Miche kufa karibu na ardhi, shina kuwa nyembamba na kuanguka, udongo wenye ukungu', 'Wastani', 'PlantVillage');

-- ── STEP 8: SEED DATA — AGROVETS ─────────────────────────

INSERT INTO agrovets (shop_name, region, district, area, gps_lat, gps_lng, phone, products, opening_hours, verified) VALUES
('Kilimo Bora Agrovet', 'Morogoro', 'Kilosa', 'Kilosa Mjini', -6.8278, 36.9896, '+255712345678', 'Mbegu, Mbolea, Dawa za wadudu, Vifaa vya shamba', '7am - 6pm', false),
('Shamba Bora Supplies', 'Morogoro', 'Morogoro Urban', 'Sokoni Kuu', -6.8242, 37.6607, '+255718234567', 'Mbegu za mbogamboga, Mbolea NPK, Dawa za ukungu', '8am - 6pm', false),
('Arusha Agricultural Inputs', 'Arusha', 'Arusha Urban', 'Sokoni Mjini', -3.3869, 36.6827, '+255754123456', 'Mbegu za nyanya na mahindi, Dawa za wadudu, Umwagiliaji', '7am - 7pm', false),
('Kilimanjaro Agro Center', 'Kilimanjaro', 'Moshi Urban', 'Moshi Mjini', -3.3549, 37.3407, '+255766345678', 'Mbegu, Mbolea, Dawa, Vifaa vya bustani', '7:30am - 5:30pm', false),
('Mbeya Farm Supplies', 'Mbeya', 'Mbeya Urban', 'Karibu na Soko Kuu', -8.9094, 33.4608, '+255752456789', 'Mbegu za mahindi na maharagwe, NPK, CAN, Dawa', '7am - 6pm', false),
('Iringa Kilimo Shop', 'Iringa', 'Iringa Urban', 'Karibu na Hospitali', -7.7706, 35.6924, '+255714567890', 'Mbegu, Mbolea, Madawa ya mimea, Vifaa vya umwagiliaji', '7am - 5pm', false),
('Dodoma Agro Services', 'Dodoma', 'Dodoma Urban', 'Kando ya Barabara Kuu', -6.1722, 35.7395, '+255723678901', 'Mbegu, Mbolea, Dawa, Mbegu za mtama na alizeti', '7am - 6pm', false),
('Dar Farmers Center', 'Pwani', 'Temeke', 'Kariakoo', -6.8160, 39.2803, '+255744789012', 'Mbegu, Mbolea, Dawa za wadudu, Sprei', '8am - 7pm', false),
('Tabora Agro Shop', 'Tabora', 'Tabora Urban', 'Soko la Kati', -5.0167, 32.8000, '+255735890123', 'Mbegu za pamba na mahindi, Mbolea, Dawa', '7am - 5pm', false),
('Mwanza Agricultural Depot', 'Mwanza', 'Nyamagana', 'Karibu na Bandari', -2.5167, 32.9000, '+255726901234', 'Mbegu, Mbolea, Dawa za wadudu, Vifaa vya uvuvi', '7am - 6pm', false);
