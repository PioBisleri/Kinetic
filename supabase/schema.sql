-- ---------------------------------------------------------------------------
-- Kinetic — Supabase remote schema (Phase 7 sync)
--
-- Setup: paste this whole file into the Supabase dashboard → SQL Editor →
-- Run, then build the app with:
--
--   flutter build apk \
--     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
--     --dart-define=SUPABASE_ANON_KEY=<anon key>
--
-- Design notes:
--  * Every table is scoped by (user_id, id) with RLS `user_id = auth.uid()`;
--    the app writes user_id explicitly from the session, the default covers
--    manual inserts from the SQL editor.
--  * `updated_at` drives the pull cursor (last-write-wins per row) and
--    `deleted_at` is the tombstone: rows are NEVER hard-deleted remotely,
--    except as a side effect of `replaceChildren` (children ride parents —
--    a push makes the parent's remote children exactly match the device).
--  * There is no `synced_at` here: that column is local bookkeeping and
--    never crosses the wire.
--  * Rollup tables (muscle_volume_daily, exercise_history, muscle_grade_-
--    history), muscle_groups and the local sync_queue are intentionally not
--    synced: rollups are rebuilt per device from synced sets, the muscle
--    catalog is identical seed content everywhere.
-- ---------------------------------------------------------------------------

-- ------------------------------- profile ---------------------------------

create table if not exists public.profiles (
  user_id       uuid not null default auth.uid(),
  id            text not null, -- 'local' on every device; identity comes from user_id
  username      text,
  unit_system   text not null default 'kg',
  theme         text not null default 'dark',
  bodyweight_kg double precision,
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  primary key (user_id, id)
);

-- ------------------------------- exercises --------------------------------

create table if not exists public.exercises (
  user_id            uuid not null default auth.uid(),
  id                 text not null, -- seed slugs or 'cus_<uuid>'
  name               text not null,
  mechanics          text not null,
  force_type         text,
  category           text not null default 'barbell',
  primary_muscle_id  text not null,
  equipment          text not null default '[]',
  default_metric     text not null default 'weight_reps',
  animation_kind     text not null default 'none',
  animation_ref      text,
  thumbnail_ref      text,
  is_custom          boolean not null default false,
  owner_id           text, -- 'local' for custom rows, null for seed rows
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz,
  primary key (user_id, id)
);

-- Children: replaced wholesale when their parent is pushed.
create table if not exists public.exercise_muscle_map (
  user_id      uuid not null default auth.uid(),
  exercise_id  text not null,
  muscle_id    text not null,
  contribution double precision not null default 1.0,
  role         text not null default 'secondary',
  primary key (user_id, exercise_id, muscle_id)
);

-- ------------------------------- routines ---------------------------------

create table if not exists public.routines (
  user_id     uuid not null default auth.uid(),
  id          text not null,
  name        text not null,
  description text,
  order_index integer not null default 0,
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  primary key (user_id, id)
);

create table if not exists public.routine_exercises (
  user_id        uuid not null default auth.uid(),
  id             text not null,
  routine_id     text not null,
  exercise_id    text not null,
  order_index    integer not null,
  superset_group integer,
  target_sets    integer not null default 3,
  target_reps    integer not null default 8,
  target_rpe     double precision,
  target_weight  double precision,
  rest_seconds   integer not null default 90,
  is_warmup      boolean not null default false,
  notes          text,
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz,
  primary key (user_id, id)
);

-- -------------------------------- workouts --------------------------------

create table if not exists public.workouts (
  user_id       uuid not null default auth.uid(),
  id            text not null,
  routine_id    text,
  status        text not null default 'active', -- active | completed | abandoned
  started_at    timestamptz not null,
  ended_at      timestamptz,
  duration_sec  integer,
  total_volume  double precision not null default 0,
  notes         text,
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  primary key (user_id, id)
);

create table if not exists public.workout_sets (
  user_id        uuid not null default auth.uid(),
  id             text not null,
  workout_id     text not null,
  exercise_id    text not null,
  order_index    integer not null,
  set_type       text not null default 'working',
  superset_group integer,
  weight_kg      double precision, -- always kilograms
  reps           integer,
  rpe            double precision,
  distance_m     double precision,
  duration_sec   integer,
  heart_rate     integer,
  is_completed   boolean not null default false,
  logged_at      timestamptz,
  notes          text,
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz,
  primary key (user_id, id)
);

-- --------------------------------- indexes --------------------------------
-- fetchChanged scans updated_at per user; children are fetched per parent.

create index if not exists profiles_updated_at_idx     on public.profiles            (user_id, updated_at);
create index if not exists exercises_updated_at_idx    on public.exercises           (user_id, updated_at);
create index if not exists routines_updated_at_idx     on public.routines            (user_id, updated_at);
create index if not exists workouts_updated_at_idx     on public.workouts            (user_id, updated_at);
create index if not exists exercise_map_exercise_idx   on public.exercise_muscle_map (user_id, exercise_id);
create index if not exists routine_exercises_routine_idx on public.routine_exercises (user_id, routine_id);
create index if not exists workout_sets_workout_idx    on public.workout_sets        (user_id, workout_id);

-- ---------------------------------- RLS -----------------------------------

alter table public.profiles            enable row level security;
alter table public.exercises           enable row level security;
alter table public.exercise_muscle_map enable row level security;
alter table public.routines            enable row level security;
alter table public.routine_exercises   enable row level security;
alter table public.workouts            enable row level security;
alter table public.workout_sets        enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'exercises', 'exercise_muscle_map',
    'routines', 'routine_exercises', 'workouts', 'workout_sets'
  ] loop
    execute format(
      'drop policy if exists "own rows" on public.%I;' ||
      'create policy "own rows" on public.%I ' ||
      'for all to authenticated ' ||
      'using (user_id = auth.uid()) ' ||
      'with check (user_id = auth.uid())',
      t, t
    );
  end loop;
end $$;
