-- ============================================================
-- Shamba Smart — Social & Messaging Tables
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Add role column to existing farmers table
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'mkulima';
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS color_hex TEXT DEFAULT '#2E7D32';
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS extra_info TEXT DEFAULT '';

-- 2. Direct messages between users
CREATE TABLE IF NOT EXISTS direct_messages (
  id          TEXT PRIMARY KEY,
  from_id     TEXT NOT NULL,
  from_name   TEXT NOT NULL,
  from_role   TEXT DEFAULT 'mkulima',
  to_id       TEXT NOT NULL,
  to_name     TEXT NOT NULL,
  to_role     TEXT DEFAULT 'mkulima',
  content     TEXT NOT NULL,
  type        TEXT DEFAULT 'text',
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Community posts
CREATE TABLE IF NOT EXISTS community_posts (
  id            TEXT PRIMARY KEY,
  author_id     TEXT NOT NULL,
  author_name   TEXT NOT NULL,
  author_role   TEXT NOT NULL,
  author_region TEXT NOT NULL,
  topic         TEXT NOT NULL,
  content       TEXT NOT NULL,
  liked_by_ids  TEXT[] DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Community replies
CREATE TABLE IF NOT EXISTS community_replies (
  id          TEXT PRIMARY KEY,
  post_id     TEXT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id   TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_role TEXT NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Enable RLS on all new tables
ALTER TABLE direct_messages   ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_replies ENABLE ROW LEVEL SECURITY;

-- 6. Permissive policies (app uses anon key — all authenticated users can access)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='direct_messages' AND policyname='allow_all_direct_messages') THEN
    CREATE POLICY "allow_all_direct_messages" ON direct_messages FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='community_posts' AND policyname='allow_all_community_posts') THEN
    CREATE POLICY "allow_all_community_posts" ON community_posts FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='community_replies' AND policyname='allow_all_community_replies') THEN
    CREATE POLICY "allow_all_community_replies" ON community_replies FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- 7. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dm_from_id   ON direct_messages(from_id);
CREATE INDEX IF NOT EXISTS idx_dm_to_id     ON direct_messages(to_id);
CREATE INDEX IF NOT EXISTS idx_dm_created   ON direct_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cp_created   ON community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cr_post_id   ON community_replies(post_id);
CREATE INDEX IF NOT EXISTS idx_farmers_role ON farmers(role);

-- ============================================================
-- Enable Realtime for instant message delivery
-- Run this AFTER the tables above are created
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE community_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE community_replies;

-- ============================================================
-- Add image support to community_posts
-- Run this in Supabase SQL Editor
-- ============================================================
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT NULL;

-- Create storage bucket for community images (run once)
-- After running the SQL, also go to:
-- Supabase → Storage → Create bucket → Name: "community-images" → Public: ON
