-- Shamba Smart — edit/delete posts & messages + app feedback
-- Run in the Supabase SQL editor.

-- ── 1. Chat: edited flag + owner update/delete RLS ──────────────────────────
alter table public.direct_messages
  add column if not exists edited boolean not null default false;

-- NOTE: from_id / author_id are TEXT columns (they store the uuid as a string),
-- while auth.uid() returns uuid — so we cast auth.uid()::text in comparisons.

-- Sender may edit their own messages.
drop policy if exists "dm update own" on public.direct_messages;
create policy "dm update own"
  on public.direct_messages for update to authenticated
  using (from_id = auth.uid()::text)
  with check (from_id = auth.uid()::text);

-- Sender may delete their own messages.
drop policy if exists "dm delete own" on public.direct_messages;
create policy "dm delete own"
  on public.direct_messages for delete to authenticated
  using (from_id = auth.uid()::text);

-- ── 2. Community: author update/delete RLS ──────────────────────────────────
drop policy if exists "posts update own" on public.community_posts;
create policy "posts update own"
  on public.community_posts for update to authenticated
  using (author_id = auth.uid()::text)
  with check (author_id = auth.uid()::text);

drop policy if exists "posts delete own" on public.community_posts;
create policy "posts delete own"
  on public.community_posts for delete to authenticated
  using (author_id = auth.uid()::text);

-- Allow deleting replies belonging to a post the user is removing (their own
-- replies, and replies under their own posts).
drop policy if exists "replies delete own" on public.community_replies;
create policy "replies delete own"
  on public.community_replies for delete to authenticated
  using (
    author_id = auth.uid()::text
    or post_id in (select id from public.community_posts where author_id = auth.uid()::text)
  );

-- ── 3. App feedback ─────────────────────────────────────────────────────────
create table if not exists public.app_feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  rating      int not null check (rating between 1 and 5),
  message     text,
  app_version text,
  created_at  timestamptz not null default now()
);

alter table public.app_feedback enable row level security;

drop policy if exists "feedback insert own" on public.app_feedback;
create policy "feedback insert own"
  on public.app_feedback for insert to authenticated
  with check (user_id = auth.uid());
