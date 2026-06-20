-- Shamba Smart — edit/delete posts & messages + app feedback
-- Run in the Supabase SQL editor.

-- ── 1. Chat: edited flag + owner update/delete RLS ──────────────────────────
alter table public.direct_messages
  add column if not exists edited boolean not null default false;

-- Sender may edit their own messages.
drop policy if exists "dm update own" on public.direct_messages;
create policy "dm update own"
  on public.direct_messages for update to authenticated
  using (from_id = auth.uid())
  with check (from_id = auth.uid());

-- Sender may delete their own messages.
drop policy if exists "dm delete own" on public.direct_messages;
create policy "dm delete own"
  on public.direct_messages for delete to authenticated
  using (from_id = auth.uid());

-- ── 2. Community: author update/delete RLS ──────────────────────────────────
drop policy if exists "posts update own" on public.community_posts;
create policy "posts update own"
  on public.community_posts for update to authenticated
  using (author_id = auth.uid())
  with check (author_id = auth.uid());

drop policy if exists "posts delete own" on public.community_posts;
create policy "posts delete own"
  on public.community_posts for delete to authenticated
  using (author_id = auth.uid());

-- Allow deleting replies belonging to a post the user is removing (their own
-- replies, and replies under their own posts).
drop policy if exists "replies delete own" on public.community_replies;
create policy "replies delete own"
  on public.community_replies for delete to authenticated
  using (
    author_id = auth.uid()
    or post_id in (select id from public.community_posts where author_id = auth.uid())
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
