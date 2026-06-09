-- Marketplace listings table for Shamba Smart P2P trading
CREATE TABLE IF NOT EXISTS listings (
  id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL,
  seller_name TEXT NOT NULL,
  seller_role TEXT NOT NULL DEFAULT 'mkulima',
  seller_color_hex TEXT DEFAULT '#2E7D32',
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  price NUMERIC NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'kg',
  quantity_available INTEGER NOT NULL DEFAULT 1,
  location TEXT NOT NULL DEFAULT '',
  emoji TEXT DEFAULT '🌱',
  badge_text TEXT,
  badge_color_hex TEXT,
  image_urls TEXT[] DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listings_seller ON listings(seller_id);

ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active listings"
  ON listings FOR SELECT
  USING (status = 'active');

CREATE POLICY "Sellers can insert own listings"
  ON listings FOR INSERT
  WITH CHECK (auth.uid()::text = seller_id OR seller_id IS NOT NULL);

CREATE POLICY "Sellers can update own listings"
  ON listings FOR UPDATE
  USING (auth.uid()::text = seller_id);
