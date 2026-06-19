-- Shamba Smart — Pesticide safety status (post Jan-2026 TPHPA purge)
-- Run in the Supabase SQL editor.
--
-- The existing pesticide data came from a 2011 registered list and has no
-- safety status. In Jan 2026 TPHPA withdrew 675+ products and flagged 130 as
-- Highly Hazardous. We add explicit approval status so the app can recommend
-- ONLY currently-approved products.

alter table public.pesticides
  add column if not exists approval_status text not null default 'unknown'
    check (approval_status in ('approved', 'withdrawn', 'hhp', 'unknown')),
  add column if not exists last_verified_date date,
  add column if not exists status_source text;   -- TPHPA / manual / etc.

-- CRITICAL: the legacy rows default everything to tpri_registered = true, which
-- is NOT a safety guarantee post-2026. Until verified against the current TPHPA
-- list, treat them as UNKNOWN so the app never recommends them. The app only
-- recommends approval_status = 'approved'.
update public.pesticides
  set approval_status = 'unknown'
  where approval_status is null or approval_status = '';

create index if not exists idx_pesticides_approval
  on public.pesticides (approval_status);

-- Read access for the IPM advisor: anyone may read, but the app/edge function
-- must filter to approval_status = 'approved' when recommending.
-- (Existing RLS/read policies on pesticides are left unchanged.)
