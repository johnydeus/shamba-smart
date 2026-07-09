-- Shamba Smart — storage RLS for the `leaf-photos` bucket (scan diagnosis photos).
-- APPLIED to production (pbngmusrzvzycdjltrbs) on 2026-07-09 via CLI.
--
-- Root cause it fixes: storage.objects had RLS policies only for the
-- `community-images` bucket, so every upload to `leaf-photos` was denied.
-- SupabaseService.saveDiagnosis uploaded the photo BEFORE the insert, so the
-- denied upload threw and the diagnoses row was never written (0 rows).
-- (The app-side decoupling — save the row even if upload fails — is a separate
-- commit; this restores the upload itself.)
--
-- Mirrors the working "shamba community-images {insert,read}" policies:
--   INSERT to authenticated, SELECT to authenticated, scoped by bucket_id.
-- No UPDATE policy: uploads use unique timestamped filenames (no overwrite).

drop policy if exists "shamba leaf-photos insert" on storage.objects;
create policy "shamba leaf-photos insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'leaf-photos');

drop policy if exists "shamba leaf-photos read" on storage.objects;
create policy "shamba leaf-photos read" on storage.objects
  for select to authenticated
  using (bucket_id = 'leaf-photos');

-- Verify:
-- select polname, polcmd, polroles::regrole[]
--   from pg_policy where polrelid='storage.objects'::regclass
--   and polname like '%leaf-photos%';
