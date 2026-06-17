-- Shamba Smart — chat image support
-- Adds the column needed for photos in private chat (Mazungumzo).
-- Run this in the Supabase SQL editor (or via `supabase db push`).

-- 1. Store the uploaded photo URL on each direct message.
alter table public.direct_messages
  add column if not exists image_url text;

-- 2. Storage bucket.
--    Private chat photos reuse the existing PUBLIC `community-images` bucket
--    under a `chat/` folder, with random UUID filenames so URLs are
--    unguessable. No new bucket is required.
--
--    If you prefer a dedicated bucket instead, create a PUBLIC bucket named
--    `chat-images` in Storage and change `_kChatImageBucket` in
--    lib/features/messaging/data/message_repository.dart accordingly.
--
--    Confirm `community-images` exists and is public (it already powers
--    community post photos):
--      select id, public from storage.buckets where id = 'community-images';
