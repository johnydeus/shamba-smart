-- ================================================================
-- SHAMBA SMART — Complete Database Setup + Data Insertion
-- Run in: Supabase Dashboard → SQL Editor → New Query → Run
-- ================================================================

-- STEP 1: Fix permissions
ALTER TABLE market_prices DISABLE ROW LEVEL SECURITY;
ALTER TABLE pesticides    DISABLE ROW LEVEL SECURITY;
ALTER TABLE agrovets      DISABLE ROW LEVEL SECURITY;
ALTER TABLE agrovets ADD COLUMN IF NOT EXISTS source TEXT;

-- STEP 2: Create missing tables
CREATE TABLE IF NOT EXISTS seed_varieties (
  id SERIAL PRIMARY KEY, variety_name TEXT NOT NULL, crop_type_en TEXT,
  crop_type_sw TEXT, maturity_days INT, yield_kg_per_acre FLOAT,
  recommended_regions TEXT[], breeder TEXT, tosci_certified BOOLEAN DEFAULT TRUE,
  drought_tolerant BOOLEAN, disease_resistant TEXT[], source_url TEXT,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE seed_varieties DISABLE ROW LEVEL SECURITY;
GRANT ALL ON seed_varieties TO anon;
GRANT USAGE, SELECT ON SEQUENCE seed_varieties_id_seq TO anon;
CREATE TABLE IF NOT EXISTS research_data (
  id SERIAL PRIMARY KEY, title TEXT NOT NULL, content TEXT, data_type TEXT,
  crop_name TEXT, pest_or_disease TEXT, recommendation TEXT,
  source TEXT DEFAULT 'TPRI', source_url TEXT, published_date DATE,
  scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE research_data DISABLE ROW LEVEL SECURITY;
GRANT ALL ON research_data TO anon;
GRANT USAGE, SELECT ON SEQUENCE research_data_id_seq TO anon;
CREATE TABLE IF NOT EXISTS fertilisers (
  id SERIAL PRIMARY KEY, product_name TEXT NOT NULL, nitrogen_pct FLOAT,
  phosphorus_pct FLOAT, potassium_pct FLOAT, npk_ratio TEXT,
  recommended_crops TEXT[], application_rate TEXT, supplier TEXT,
  price_tzs INT, source_url TEXT, scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE fertilisers DISABLE ROW LEVEL SECURITY;
GRANT ALL ON fertilisers TO anon;
GRANT USAGE, SELECT ON SEQUENCE fertilisers_id_seq TO anon;
CREATE TABLE IF NOT EXISTS agro_products (
  id SERIAL PRIMARY KEY, product_name TEXT NOT NULL, category TEXT,
  description TEXT, target_crops TEXT[], supplier TEXT, price_tzs INT,
  source_url TEXT, scraped_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE agro_products DISABLE ROW LEVEL SECURITY;
GRANT ALL ON agro_products TO anon;
GRANT USAGE, SELECT ON SEQUENCE agro_products_id_seq TO anon;
CREATE TABLE IF NOT EXISTS scrape_logs (
  id SERIAL PRIMARY KEY, target_name TEXT NOT NULL, target_url TEXT,
  records_scraped INT DEFAULT 0, status TEXT, error_message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(), completed_at TIMESTAMPTZ
);
ALTER TABLE scrape_logs DISABLE ROW LEVEL SECURITY;
GRANT ALL ON scrape_logs TO anon;
GRANT USAGE, SELECT ON SEQUENCE scrape_logs_id_seq TO anon;

-- STEP 3: Grant access to existing tables
GRANT ALL ON pesticides    TO anon;
GRANT ALL ON market_prices TO anon;
GRANT ALL ON agrovets      TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- STEP 4: Insert market prices data
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Kariakoo — Dar es Salaam',480,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Arusha Central Market',420,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Mbeya Market',380,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Dodoma Central Market',390,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Mwanza Market',460,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mahindi','Morogoro Market',410,'inashuka','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Nyanya','Kariakoo — Dar es Salaam',1200,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Nyanya','Arusha Central Market',900,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Nyanya','Mbeya Market',800,'inashuka','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Nyanya','Mwanza Market',1100,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Nyanya','Dodoma Central Market',950,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Maharagwe','Kariakoo — Dar es Salaam',2200,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Maharagwe','Arusha Central Market',1900,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Maharagwe','Mbeya Market',1700,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mchele','Kariakoo — Dar es Salaam',1800,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mchele','Morogoro Market',1650,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Mchele','Mwanza Market',1750,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Vitunguu','Kariakoo — Dar es Salaam',1800,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Vitunguu','Arusha Central Market',1600,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Karoti','Arusha Central Market',1200,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Karoti','Kariakoo — Dar es Salaam',1400,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Ndizi','Kariakoo — Dar es Salaam',600,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Ndizi','Arusha Central Market',500,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Ndizi','Mbeya Market',450,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Muhogo','Kariakoo — Dar es Salaam',350,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Muhogo','Dodoma Central Market',320,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Pamba','Mwanza Market',1150,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Alizeti','Dodoma Central Market',1400,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Alizeti','Mbeya Market',1300,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Viazi vitamu','Kariakoo — Dar es Salaam',700,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Kahawa','Kilimanjaro Market',4000,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Korosho','Mtwara Market',4800,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Korosho','Lindi Market',5000,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Karanga','Kariakoo — Dar es Salaam',3000,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Soya','Mbeya Market',1200,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Avokado','Arusha Central Market',2000,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Embe','Kariakoo — Dar es Salaam',800,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Viazi','Arusha Central Market',1000,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Kabichi','Arusha Central Market',800,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Sukuma wiki','Kariakoo — Dar es Salaam',500,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Tikiti maji','Kariakoo — Dar es Salaam',600,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Pilipili hoho','Kariakoo — Dar es Salaam',2500,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Bamia','Kariakoo — Dar es Salaam',1500,'inapanda','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Bilinganya','Kariakoo — Dar es Salaam',1200,'imara','pipeline_data','2026-05-20');
INSERT INTO market_prices(crop_name,market_name,price_tzs_kg,trend,source,price_date) VALUES('Tango','Kariakoo — Dar es Salaam',1000,'imara','pipeline_data','2026-05-20');

-- STEP 5: Insert agrovets data
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('AgriPlus Agrovet','Arusha','Arusha','+255 27 250 1234',true,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Selian','Arusha','Arusha','+255 27 255 3623',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('East African Seeds','Arusha','Arusha','+255 27 250 7775',true,'company');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Syngenta East Africa','Dar es Salaam','Ilala','+255 22 260 3000',true,'company');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Balton Tanzania','Dar es Salaam','Ilala','+255 22 218 0033',true,'company');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Yara Tanzania','Dar es Salaam','Ilala','+255 22 286 4000',true,'company');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Mikocheni','Dar es Salaam','Kinondoni','+255 22 277 3822',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Mbeya Agro Services','Mbeya','Mbeya City','+255 25 250 1100',true,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Uyole','Mbeya','Mbeya','+255 25 250 0291',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Morogoro Agrovet','Morogoro','Morogoro','+255 23 260 4500',true,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Ilonga','Morogoro','Kilosa','+255 23 262 0011',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Dodoma Agro Supplies','Dodoma','Dodoma','+255 26 232 0200',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Makutupora','Dodoma','Dodoma','+255 26 232 0035',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Kilimanjaro Agrovet','Kilimanjaro','Moshi','+255 27 275 2456',true,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TACRI Lyamungu','Kilimanjaro','Hai','+255 27 275 4264',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Ukiriguru','Mwanza','Misungwi','+255 28 250 0067',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Maruku Bukoba','Kagera','Bukoba','+255 28 222 0310',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Tanga Agro Supplies','Tanga','Tanga City','+255 27 264 0200',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('TARI Naliendele','Mtwara','Mtwara','+255 23 233 4009',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('ZARI Zanzibar','Zanzibar','Urban/West','+255 24 223 4040',true,'TARI');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Iringa Kilimo Bora','Iringa','Iringa','+255 26 270 0334',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Njombe Kilimo','Njombe','Njombe','+255 26 278 0300',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Singida Agrovet','Singida','Singida','+255 26 250 0180',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Tabora Agro Center','Tabora','Tabora','+255 26 260 0400',false,'directory');
INSERT INTO agrovets(shop_name,region,district,phone,verified,source) VALUES('Kigoma Agro Dealers','Kigoma','Kigoma','+255 28 280 0200',false,'directory');

-- STEP 6: Insert seed varieties
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('DK8031','maize','Mahindi',110,3400,'Dekalb/Bayer',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('H614D','maize','Mahindi',120,3200,'KARI/SEEDCO',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Seedco SC403','maize','Mahindi',100,2800,'Seedco',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('TWIGA','maize','Mahindi',95,2400,'TARI Kibaha',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Kilima','maize','Mahindi',105,2600,'TARI Uyole',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Pioneer 30G19','maize','Mahindi',108,3600,'Pioneer/Corteva',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Tengeru 97','tomato','Nyanya',80,8000,'TARI Tengeru',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Cal J','tomato','Nyanya',75,7200,'Calwest Seed',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Roma VF','tomato','Nyanya',75,6400,'Various',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Anna F1','tomato','Nyanya',68,12000,'East African Seeds',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Jesca','beans','Maharagwe',75,800,'TARI Selian',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Selian 97','beans','Maharagwe',80,900,'TARI Selian',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Lyamungu 85','beans','Maharagwe',85,1000,'TARI Lyamungu',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Saro 5','rice','Mchele',115,1600,'TARI Dakawa',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('TXD 306','rice','Mchele',110,2000,'TARI Dakawa',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Mkombozi','cassava','Muhogo',365,6000,'TARI Kibaha',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Naliendele','cassava','Muhogo',365,7200,'TARI Naliendele',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Aguara 6','sunflower','Alizeti',105,600,'Advanta Seeds',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Tegemeo','sorghum','Mtama',100,1600,'East African Seeds',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Pendo','groundnut','Karanga',110,1200,'TARI Naliendele',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Bombay Red','onion','Vitunguu',120,4400,'Various',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Ejumula','sweet potato','Viazi vitamu',120,3200,'TARI',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Fahari','wheat','Ngano',110,800,'TARI Selian',true,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Lyamungu Coffee','coffee','Kahawa',1095,400,'TACRI',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Asante','potato','Viazi',110,2500,'TARI Uyole',false,true,'https://tosci.go.tz');
INSERT INTO seed_varieties(variety_name,crop_type_en,crop_type_sw,maturity_days,yield_kg_per_acre,breeder,drought_tolerant,tosci_certified,source_url) VALUES('Tigoni','potato','Viazi',100,3000,'KEPHIS/TARI',false,true,'https://tosci.go.tz');

-- STEP 7: Insert fertilisers
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Yara Mila ACTYVA S','12-11-18',12.0,11.0,18.0,'200-300 kg/ha','Yara Tanzania',95000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Yara Mila WINNER','15-15-15',15.0,15.0,15.0,'200 kg/ha','Yara Tanzania',90000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Yara Mila CEREAL','27-7-10',27.0,7.0,10.0,'150-200 kg/ha','Yara Tanzania',88000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('YaraBela SULFAN','24N+6S',24.0,0.0,0.0,'100-150 kg/ha topdress','Yara Tanzania',72000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Urea 46N','46-0-0',46.0,0.0,0.0,'100-150 kg/ha topdress','Various',65000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('DAP 18:46:0','18-46-0',18.0,46.0,0.0,'100-150 kg/ha planting','Various',92000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('CAN 26%','26N',26.0,0.0,0.0,'100-200 kg/ha topdress','Various',70000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Minjingu Mazao NPK','10-20-10',10.0,20.0,10.0,'200 kg/ha planting','Minjingu Ltd',75000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Minjingu Rock Phosphate','0-28-0',0.0,28.0,0.0,'250-400 kg/ha','Minjingu Ltd',45000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('NPK 17:17:17','17-17-17',17.0,17.0,17.0,'200 kg/ha','Various',85000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('NPK 20:10:10','20-10-10',20.0,10.0,10.0,'150-200 kg/ha','Various',80000,'https://www.yara.co.tz');
INSERT INTO fertilisers(product_name,npk_ratio,nitrogen_pct,phosphorus_pct,potassium_pct,application_rate,supplier,price_tzs,source_url) VALUES('Bayfolan Forte','11-8-6',11.0,8.0,6.0,'2-3 L/ha foliar','Bayer',38000,'https://www.yara.co.tz');

-- STEP 8: Insert agro products (Balton)
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Amistar Top 325SC','Fungicide','Syngenta/Balton','Azoxystrobin+Difenoconazole — broad spectrum systemic',28000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Actara 25WG','Insecticide','Balton Tanzania','Thiamethoxam — systemic, long residual',35000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Karate Zeon 10CS','Insecticide','Balton Tanzania','Lambda-cyhalothrin microencapsulated',22000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Folicur 25EW','Fungicide','Balton Tanzania','Tebuconazole systemic fungicide',26000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Nurelle D 505EC','Insecticide','Balton Tanzania','Chlorpyrifos+Cypermethrin combination',18000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Gramoxone 200SL','Herbicide','Balton Tanzania','Paraquat contact herbicide',24000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Stomp Aqua','Herbicide','Balton Tanzania','Pendimethalin pre-emergence',21000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Bayfolan Forte','Foliar Fertiliser','Balton Tanzania','NPK+micronutrients foliar spray',38000,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Decis 25EC','Insecticide','Balton Tanzania','Deltamethrin broad spectrum',7500,'https://www.balton.co.tz');
INSERT INTO agro_products(product_name,category,supplier,description,price_tzs,source_url) VALUES('Score 250EC','Fungicide','Balton Tanzania','Difenoconazole leaf diseases',26000,'https://www.balton.co.tz');

-- STEP 9: Insert research data (TPRI)
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Fall Armyworm (FAW) Management in Maize','maize','Fall Armyworm (Spodoptera frugiperda)','Apply Coragen 20SC at 20ml/15L or Emamectin 5SG at 10g/15L. Spray early morning. Ensure funnel coverage.','pest_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Tomato Yellow Leaf Curl Virus (TYLCV)','tomato','TYLCV','Use TYLCV-resistant varieties: Anna F1, Shanty F1. Control whitefly with Confidor 200SL at 10ml/15L.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Cassava Brown Streak Disease (CBSD)','cassava','CBSD','Plant CBSD-tolerant varieties: Mkombozi, Naliendele. Use clean planting material. Rogue infected plants.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Coffee Berry Disease (CBD)','coffee','CBD / Colletotrichum kahawae','Apply Kocide 2000 at 30g/15L every 2-3 weeks during berry development. Plant resistant varieties.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Maize Streak Virus (MSV)','maize','MSV','Plant MSV-resistant varieties: DK8031, TWIGA. Control leafhoppers at establishment.','pest_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Diamondback Moth in Brassicas','cabbage','Diamondback Moth (Plutella xylostella)','Apply Tracer 480SC (Spinosad) at 3ml/15L. Rotate insecticide classes.','pest_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Late Blight of Potato','potato','Late Blight (Phytophthora infestans)','Apply Ridomil Gold MZ 68WG at 35g/15L. Begin preventive spraying in humid weather.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Rice Blast Disease','rice','Rice Blast (Magnaporthe oryzae)','Apply Beam 75WP at 15g/15L. Plant resistant varieties: TXD 306, Saro 5.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Cotton Bollworm Complex','cotton','Bollworm (Helicoverpa armigera)','Spray Coragen 20SC at 20ml/15L. Use pheromone traps for monitoring.','pest_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Banana Fusarium Wilt Alert','banana','Fusarium Wilt (Panama Disease TR4)','Plant NARITA resistant varieties. Quarantine infected fields. No effective chemical control.','disease_alert','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Optimal Fertiliser Guide for Maize','maize',NULL,'Apply 1 bag DAP at planting + 1 bag CAN at 4-6 weeks after emergence. Supplement with 2 tons manure/acre.','research_finding','TPRI','https://tpri.go.tz');
INSERT INTO research_data(title,crop_name,pest_or_disease,recommendation,data_type,source,source_url) VALUES('Bean Mosaic Virus Management','beans','Bean Common Mosaic Virus','Use resistant varieties: Jesca, Selian 97. Control aphid vectors with Mospilan 20SP.','disease_alert','TPRI','https://tpri.go.tz');

SELECT 'All data inserted successfully!' AS result;