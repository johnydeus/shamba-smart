-- Shamba Smart — farms RLS: region boundary for Afisa Kilimo + owner-only CRUD.
-- APPLIED to production (pbngmusrzvzycdjltrbs) on 2026-07-07 via CLI.
-- Kept here for the record / re-runnable (idempotent drops).
--
-- Before: farms_select/update/delete all had USING (true) — any authenticated
-- user could read, MODIFY, or DELETE any farm nationwide, and the afisa saw
-- every region. After: owners get full CRUD on their own rows only; an afisa
-- can READ farms only where farm.region matches their own profiles.region.
--
-- Notes:
-- * farmer_id is TEXT (legacy timestamp ids exist) — hence auth.uid()::text.
--   Legacy rows with timestamp farmer_ids have no owner under these policies
--   (they never matched auth.uid() anyway); afisa region-read still covers
--   them for officers of that region.
-- * The profiles subquery works because profiles has "profiles_read_all"
--   (and at minimum own-row read).
-- * App-side mirror: afisa_hub_screen._loadFarms also filters .eq('region').

drop policy if exists "farms_select"               on public.farms;
drop policy if exists "farms_update"               on public.farms;
drop policy if exists "farms_delete"               on public.farms;
drop policy if exists "farms_insert"               on public.farms;
drop policy if exists "Afisa anaona mashamba yote" on public.farms;

create policy "farms owner select" on public.farms for select
  using (farmer_id = auth.uid()::text);
create policy "farms owner insert" on public.farms for insert
  with check (farmer_id = auth.uid()::text);
create policy "farms owner update" on public.farms for update
  using (farmer_id = auth.uid()::text) with check (farmer_id = auth.uid()::text);
create policy "farms owner delete" on public.farms for delete
  using (farmer_id = auth.uid()::text);

create policy "afisa reads own-region farms" on public.farms for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (p.role = 'afisa' or p.all_roles @> '{afisa}')
        and p.region = farms.region
    )
  );

-- Verify:
-- select polname, polcmd from pg_policy where polrelid='public.farms'::regclass;
