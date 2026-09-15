-- Allow Explore-sourced cards (FR-19/FR-20). Databases created before the
-- 'explore' value was added to schema.sql have a cards_source_check that only
-- permits 'notes', which rejects Explore "Verify" inserts. Run once on those.
alter table cards drop constraint if exists cards_source_check;
alter table cards add  constraint cards_source_check check (source in ('notes','explore'));
