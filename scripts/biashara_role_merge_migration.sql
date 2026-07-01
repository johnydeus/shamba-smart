-- Shamba Smart — Merge duka + muuzaji + mwekezaji into one "Biashara" role.
-- Run in the Supabase SQL editor (service role). Mkulima and Afisa unchanged.
--
-- Model: role='biashara' + a new biashara_type sub-type
--        ('duka' | 'mwekezaji' | 'muuzaji_dalali'). The agrovets directory is
--        keyed by owner_id, not by role, so it needs NO changes.
--
-- Order matters: A2 backfills biashara_type from the legacy role BEFORE A3
-- rewrites the role. Run A0 first and act on what it reports.

-- ── A0. Probe the schema before changing anything ──────────────────────────
--   (read-only — inspect the output, then run the sections below)
select column_name, data_type, udt_name
  from information_schema.columns
  where table_name = 'profiles'
    and column_name in ('role', 'all_roles', 'biashara_type');

--   If `role`/`all_roles` are a Postgres ENUM type (udt_name is not text/_text),
--   you must first allow the new value (cannot run inside a txn block):
--     ALTER TYPE <role_enum_type> ADD VALUE IF NOT EXISTS 'biashara';
--   If there is a CHECK constraint on role, list + widen it:
select conname, pg_get_constraintdef(oid)
  from pg_constraint
  where conrelid = 'public.profiles'::regclass and contype = 'c';

-- Optional hard-rollback snapshot (keep until the merge is verified in the app):
-- create table if not exists profiles_role_backup as
--   select id, role, all_roles from public.profiles;

-- ── A1. Add the sub-type column ─────────────────────────────────────────────
alter table public.profiles
  add column if not exists biashara_type text;

alter table public.profiles
  drop constraint if exists profiles_biashara_type_chk;
alter table public.profiles
  add constraint profiles_biashara_type_chk
  check (biashara_type is null
         or biashara_type in ('duka', 'mwekezaji', 'muuzaji_dalali'));

-- ── A2. Backfill biashara_type (BEFORE remapping role) ──────────────────────
-- from the active legacy role
update public.profiles
  set biashara_type = case role
        when 'duka'      then 'duka'
        when 'mwekezaji' then 'mwekezaji'
        when 'muuzaji'   then 'muuzaji_dalali'
      end
  where role in ('duka', 'mwekezaji', 'muuzaji')
    and biashara_type is null;

-- else from all_roles (multi-role users whose ACTIVE role was something else)
update public.profiles
  set biashara_type = case
        when all_roles @> '{duka}'      then 'duka'
        when all_roles @> '{mwekezaji}' then 'mwekezaji'
        when all_roles @> '{muuzaji}'   then 'muuzaji_dalali'
      end
  where biashara_type is null
    and (all_roles && '{duka,mwekezaji,muuzaji}');

-- ── A3. Remap role + all_roles[] ────────────────────────────────────────────
update public.profiles
  set role = 'biashara'
  where role in ('duka', 'mwekezaji', 'muuzaji');

update public.profiles
  set all_roles = (
    select array_agg(distinct
      case when r in ('duka', 'mwekezaji', 'muuzaji') then 'biashara' else r end)
    from unnest(all_roles) as r)
  where all_roles && '{duka,mwekezaji,muuzaji}';

-- Keep the `farmers` mirror table consistent (register() also writes role there)
update public.farmers
  set role = 'biashara'
  where role in ('duka', 'mwekezaji', 'muuzaji');

-- ── A4. Verify ──────────────────────────────────────────────────────────────
-- Expect: NO rows with role in ('duka','muuzaji','mwekezaji');
--         every biashara row has a non-null biashara_type.
select role, biashara_type, count(*)
  from public.profiles
  group by 1, 2
  order by 1, 2;
