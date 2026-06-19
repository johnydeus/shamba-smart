-- Shamba Smart — Agrovet & Institution Directory (v2)
-- Run in the Supabase SQL editor.
--
-- Replaces the old minimal `agrovets` table (which held fabricated demo rows)
-- with a real directory: government + private + cooperative suppliers,
-- categorised by what they offer, with verification + self-registration.
--
-- SAFETY: the old table only contained made-up demo shops, so we drop it.
-- Real data is loaded by scripts/seed_agrovets.py (official sources) and grows
-- via in-app self-registration (pending -> verified).

drop table if exists public.agrovets cascade;

create table public.agrovets (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  type               text not null default 'private'
                       check (type in ('government', 'private', 'cooperative')),
  -- which of these they offer: fertilizer, seeds, pesticides, crop_buying,
  -- equipment, veterinary, advisory
  categories         text[] not null default '{}',
  region             text not null,
  district           text,
  ward               text,
  physical_address   text,
  description        text,                 -- informal ok: "opposite Kibaha market"
  latitude           double precision,     -- optional, many won't have GPS
  longitude          double precision,
  phone              text,
  whatsapp           text,
  email              text,
  is_verified        boolean not null default false,
  is_self_registered boolean not null default false,
  owner_id           uuid references auth.users(id) on delete set null,
  -- TFRA / TPHPA / TOSCI / NCD / self-registered / google
  source             text not null default 'self-registered',
  created_at         timestamptz not null default now()
);

create index idx_agrovets_region     on public.agrovets (region);
create index idx_agrovets_verified   on public.agrovets (is_verified);
create index idx_agrovets_categories on public.agrovets using gin (categories);

-- ── Row Level Security ──────────────────────────────────────────────────────
alter table public.agrovets enable row level security;

-- Everyone (even anon) can READ verified agrovets.
drop policy if exists "agrovets read verified" on public.agrovets;
create policy "agrovets read verified"
  on public.agrovets for select
  using (is_verified = true);

-- A signed-in user can read their OWN listing even before it's verified
-- (so they can see the "pending" state).
drop policy if exists "agrovets read own" on public.agrovets;
create policy "agrovets read own"
  on public.agrovets for select to authenticated
  using (owner_id = auth.uid());

-- A signed-in user can create a self-registered listing they own.
-- It starts unverified (an admin/officer verifies later).
drop policy if exists "agrovets insert own" on public.agrovets;
create policy "agrovets insert own"
  on public.agrovets for insert to authenticated
  with check (owner_id = auth.uid() and is_self_registered = true);

-- A user can edit their own listing, but cannot self-verify.
drop policy if exists "agrovets update own" on public.agrovets;
create policy "agrovets update own"
  on public.agrovets for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid() and is_verified = false);
