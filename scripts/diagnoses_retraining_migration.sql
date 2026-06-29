-- Shamba Smart — diagnoses retraining capture (Phase 5)
-- Run in the Supabase SQL editor. All columns nullable / safe — existing rows
-- and the current (flag-off) write path keep working unchanged.

alter table public.diagnoses
  add column if not exists model_used       text,  -- mkulima_v2 | gemini-flash-lite | gemini-flash | claude
  add column if not exists final_label      text,  -- the label actually shown to the farmer
  add column if not exists label_source     text,  -- mobilenet | flash-lite | flash | claude | human
  add column if not exists escalation_reason text; -- low_confidence | unknown | poor_image | flagged | needs_expert | null

-- Optional: index for retraining queries by source/model.
create index if not exists idx_diagnoses_label_source on public.diagnoses (label_source);
create index if not exists idx_diagnoses_model_used   on public.diagnoses (model_used);
