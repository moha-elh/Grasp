-- Grasp schema (spec §8). Single-user, RLS-scoped to auth.uid().
-- Run in the Supabase SQL editor.

-- === cards ===
create table if not exists cards (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  front          text not null,
  back           text not null,
  card_type      text not null check (card_type in ('anchor','mechanism','application')),
  source         text not null default 'notes' check (source in ('notes','explore')),
  source_path    text,
  source_excerpt text,
  reference_url  text,
  status         text not null default 'pending'
                   check (status in ('pending','approved','discarded','remake_pending')),
  quality        text check (quality in ('liked','disliked')),
  fsrs           jsonb not null,
  due            timestamptz,
  reps           int not null default 0,
  lapses         int not null default 0,
  card_state     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
-- Session queries: due reviews, new intake, pending vetting (FR-16/17/14).
create index if not exists cards_due_idx on cards (user_id, status, due);
create index if not exists cards_status_idx on cards (user_id, status);

-- === review_logs ===
create table if not exists review_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  card_id        uuid not null references cards(id) on delete cascade,
  rating         int not null check (rating between 1 and 4),
  reviewed_at    timestamptz not null default now(),
  elapsed_days   int not null default 0,
  scheduled_days int not null default 0
);
create index if not exists review_logs_card_idx on review_logs (card_id, reviewed_at);

-- === note_coverage ===
create table if not exists note_coverage (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid() references auth.users(id) on delete cascade,
  source_path       text not null,
  last_generated_at timestamptz,
  cards_generated   int not null default 0,
  unique (user_id, source_path)
);

-- === Row-Level Security (§8) ===
alter table cards        enable row level security;
alter table review_logs  enable row level security;
alter table note_coverage enable row level security;

create policy "own cards"    on cards        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own logs"     on review_logs  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own coverage" on note_coverage for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- === Atomic review write-back (§8) ===
-- FSRS is computed client-side; this only persists card state + log together.
create or replace function record_review(
  p_card_id uuid,
  p_fsrs jsonb,
  p_due timestamptz,
  p_reps int,
  p_lapses int,
  p_card_state text,
  p_rating int,
  p_elapsed_days int,
  p_scheduled_days int
) returns void
language plpgsql security invoker as $$
begin
  update cards
     set fsrs = p_fsrs,
         due = p_due,
         reps = p_reps,
         lapses = p_lapses,
         card_state = p_card_state,
         updated_at = now()
   where id = p_card_id and user_id = auth.uid();

  if not found then
    raise exception 'card % not found for user', p_card_id;
  end if;

  insert into review_logs (card_id, rating, elapsed_days, scheduled_days)
  values (p_card_id, p_rating, p_elapsed_days, p_scheduled_days);
end;
$$;
