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

-- 3. Storage RLS — REQUIRED for uploads to work.
--    Symptom without this: "new row violates row-level security policy"
--    (photos fail to send in chat AND fail to attach to community posts).
--    Public read only covers VIEWING; uploading needs an INSERT policy.

-- Let logged-in users upload chat + community photos to the bucket.
drop policy if exists "shamba community-images insert" on storage.objects;
create policy "shamba community-images insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'community-images');

-- Let logged-in users overwrite/update their uploads (safe to include).
drop policy if exists "shamba community-images update" on storage.objects;
create policy "shamba community-images update"
  on storage.objects for update to authenticated
  using (bucket_id = 'community-images');

-- Ensure everyone can read the photos (anon viewers in the public feed).
drop policy if exists "shamba community-images read" on storage.objects;
create policy "shamba community-images read"
  on storage.objects for select to public
  using (bucket_id = 'community-images');
