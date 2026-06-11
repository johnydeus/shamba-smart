-- ============================================================
-- Shamba Smart — Fixes Migration
-- FIX 2: Officer linking tables
-- FIX 3: Privacy settings table
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- ── FIX 2: Agricultural Officers ────────────────────────────

CREATE TABLE IF NOT EXISTS agri_officers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  full_name TEXT NOT NULL,
  title TEXT,
  qualification TEXT,
  specialisation TEXT[],
  employer TEXT,
  employee_id TEXT,
  primary_region TEXT NOT NULL,
  primary_district TEXT,
  assigned_wards TEXT[],
  coverage_radius_km FLOAT DEFAULT 50.0,
  phone TEXT,
  whatsapp TEXT,
  email TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_document_url TEXT,
  available_days TEXT[],
  farm_visit_available BOOLEAN DEFAULT FALSE,
  farm_visit_cost_tzs INT DEFAULT 0,
  farmers_served INT DEFAULT 0,
  average_rating FLOAT DEFAULT 0.0,
  total_ratings INT DEFAULT 0,
  response_time_hours FLOAT DEFAULT 24.0,
  bio TEXT,
  profile_photo_url TEXT,
  languages TEXT[] DEFAULT ARRAY['sw','en'],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS farmer_officer_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  officer_id UUID REFERENCES agri_officers(id),
  link_type TEXT DEFAULT 'regional',
  is_primary BOOLEAN DEFAULT TRUE,
  linked_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS officer_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  officer_id UUID REFERENCES agri_officers(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  message_sw TEXT,
  target_region TEXT,
  target_district TEXT,
  target_crop TEXT,
  priority TEXT DEFAULT 'normal',
  broadcast_type TEXT DEFAULT 'advisory',
  attachment_url TEXT,
  views_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS officer_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID,
  officer_id UUID REFERENCES agri_officers(id),
  rating INT CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(farmer_id, officer_id)
);

CREATE INDEX IF NOT EXISTS idx_officers_region
  ON agri_officers(primary_region, primary_district);
CREATE INDEX IF NOT EXISTS idx_officers_active
  ON agri_officers(is_active, is_verified);

-- ── FIX 3: Privacy Settings ──────────────────────────────────

CREATE TABLE IF NOT EXISTS privacy_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID UNIQUE,
  who_can_message TEXT DEFAULT 'everyone',
  show_real_name BOOLEAN DEFAULT TRUE,
  show_phone_number BOOLEAN DEFAULT FALSE,
  show_farm_location BOOLEAN DEFAULT TRUE,
  show_farm_size BOOLEAN DEFAULT TRUE,
  use_anonymous_in_forum BOOLEAN DEFAULT FALSE,
  allow_forum_quotes BOOLEAN DEFAULT TRUE,
  share_disease_data BOOLEAN DEFAULT TRUE,
  allow_research_use BOOLEAN DEFAULT TRUE,
  receive_marketing BOOLEAN DEFAULT FALSE,
  receive_officer_broadcasts BOOLEAN DEFAULT TRUE,
  receive_disaster_alerts BOOLEAN DEFAULT TRUE,
  show_online_status BOOLEAN DEFAULT TRUE,
  show_last_seen BOOLEAN DEFAULT TRUE,
  send_read_receipts BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Row Level Security ────────────────────────────────────────

ALTER TABLE agri_officers ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmer_officer_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE officer_broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE officer_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "officers_public_read" ON agri_officers;
CREATE POLICY "officers_public_read" ON agri_officers
  FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "farmer_links" ON farmer_officer_links;
CREATE POLICY "farmer_links" ON farmer_officer_links
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "broadcasts_read" ON officer_broadcasts;
CREATE POLICY "broadcasts_read" ON officer_broadcasts
  FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "officer_post_broadcasts" ON officer_broadcasts;
CREATE POLICY "officer_post_broadcasts" ON officer_broadcasts
  FOR INSERT WITH CHECK (officer_id IS NOT NULL);

DROP POLICY IF EXISTS "farmer_ratings" ON officer_ratings;
CREATE POLICY "farmer_ratings" ON officer_ratings
  FOR ALL USING (farmer_id = auth.uid());

DROP POLICY IF EXISTS "farmer_own_privacy" ON privacy_settings;
CREATE POLICY "farmer_own_privacy" ON privacy_settings
  FOR ALL USING (farmer_id = auth.uid());

-- ── Seed: 5 sample officers ───────────────────────────────────

INSERT INTO agri_officers (
  full_name, title, qualification, specialisation, employer,
  primary_region, primary_district, phone, is_active, is_verified,
  average_rating, total_ratings, response_time_hours, farmers_served,
  farm_visit_available, farm_visit_cost_tzs,
  bio
) VALUES
(
  'Dkt. Amani Mwalimu', 'Mtaalamu wa Mazao', 'BSc Agronomy, SUA',
  ARRAY['mahindi','nyanya','mbolea'], 'Wizara ya Kilimo',
  'Morogoro', 'Kilosa', '+255765000001', TRUE, TRUE,
  4.8, 23, 4.0, 47, TRUE, 25000,
  'Nina uzoefu wa miaka 12 katika kilimo cha nafaka na mbogamboga.'
),
(
  'Bi. Zawadi Msigwa', 'Afisa Kilimo', 'Diploma Kilimo, Uyole',
  ARRAY['kahawa','mahindi','viazi'], 'Serikali ya Mkoa',
  'Mbeya', 'Mbeya Vijijini', '+255713000002', TRUE, FALSE,
  4.5, 11, 12.0, 89, FALSE, 0,
  'Afisa kilimo katika wilaya ya Mbeya Vijijini.'
),
(
  'Bw. Emmanuel Komba', 'Agronomist', 'MSc Agronomy, UDSM',
  ARRAY['pamba','alizeti','soya'], 'Private Consultant',
  'Dodoma', 'Kongwa', '+255756000003', TRUE, TRUE,
  4.9, 34, 2.0, 120, TRUE, 30000,
  'Agronomist binafsi na uzoefu wa miaka 8 Dodoma na Singida.'
),
(
  'Dkt. Salma Hamisi', 'Mshauri wa TPRI', 'BSc Plant Protection, SUA',
  ARRAY['viuatilifu','magonjwa ya mazao','nyanya'], 'TPRI - Arusha',
  'Arusha', 'Arumeru', '+255784000004', TRUE, TRUE,
  4.7, 19, 6.0, 65, TRUE, 40000,
  'Mshauri kutoka TPRI. Mtaalamu wa udhibiti wa wadudu na magonjwa.'
),
(
  'Bw. Hashim Ramadhani', 'Afisa Kilimo', 'Certificate in Agriculture',
  ARRAY['mpunga','ndizi','mbogamboga'], 'Halmashauri ya Wilaya',
  'Pwani', 'Rufiji', '+255699000005', TRUE, FALSE,
  4.2, 8, 24.0, 33, FALSE, 0,
  'Afisa kilimo Pwani. Mtaalamu wa mpunga wa bonde la Rufiji.'
)
ON CONFLICT DO NOTHING;
