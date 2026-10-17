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
--    history), muscle_groups and the local rollups are intentionally not
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
  -- "Your data" (Round 5 / local schema v4) — nullable, display-only.
  height_cm     double precision,
  birth_date    text,          -- ISO yyyy-MM-dd
  sex           text,          -- female | male | other
  body_fat_pct  double precision,
  training_goal text,          -- strength | hypertrophy | general
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  format        integer not null default 1, -- 1 = plaintext, 2 = encrypted payload
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
  -- Rest + progression overrides (Round 3 / v3, Round 6 / v5): NULL
  -- inherits the Settings default (seconds) / unit default (kg step).
  rest_seconds             integer,
  progression_increment_kg double precision,
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz,
  format             integer not null default 1,
  primary key (user_id, id)
);

-- Children: replaced wholesale when their parent is pushed.
create table if not exists public.exercise_muscle_map (
  user_id      uuid not null default auth.uid(),
  exercise_id  text not null,
  muscle_id    text not null,
  contribution double precision not null default 1.0,
  role         text not null default 'secondary',
  format       integer not null default 1,
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
  format      integer not null default 1,
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
  -- Per-type set counts (Round 3 / local schema v3). target_sets stays the
  -- TOTAL; working = targetSets − warmup − drop − failure.
  warmup_sets    integer not null default 0,
  drop_sets      integer not null default 0,
  failure_sets   integer not null default 0,
  is_warmup      boolean not null default false, -- legacy v1/v2 wire flag
  notes          text,
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz,
  format         integer not null default 1,
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
  format        integer not null default 1,
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
  format         integer not null default 1,
  primary key (user_id, id)
);

-- ------------------------------- body metrics ------------------------------
-- Weight-trend points (Round 6 / local schema v6): one row per local
-- calendar day, LWW per row like profiles.

create table if not exists public.body_metrics (
  user_id     uuid not null default auth.uid(),
  id          text not null, -- local day key 'YYYY-MM-DD'
  weight_kg   double precision,
  -- Round 8 / local schema v9: daily health log widened (nullable).
  water_ml    integer,
  steps       integer,
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  format      integer not null default 1,
  primary key (user_id, id)
);

-- ------------------------------- nutrition ---------------------------------
-- Food library + daily log (Round 8 / local schema v9). Both sync flat,
-- LWW with tombstones like everything else.

create table if not exists public.foods (
  user_id      uuid not null default auth.uid(),
  id           text not null,
  name         text not null,
  brand        text,
  serving_size double precision not null default 100,
  serving_unit text not null default 'g', -- g | ml | piece
  kcal         double precision not null default 0,
  protein_g    double precision not null default 0,
  carbs_g      double precision not null default 0,
  fat_g        double precision not null default 0,
  is_custom    boolean not null default true,
  owner_id     text, -- 'local' for custom rows
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  format       integer not null default 1,
  primary key (user_id, id)
);

create table if not exists public.food_logs (
  user_id     uuid not null default auth.uid(),
  id          text not null,
  day_key     text not null, -- 'YYYY-MM-DD'
  food_id     text,          -- null for ad-hoc entries
  name        text not null, -- snapshot at log time
  servings    double precision not null default 1,
  kcal        double precision not null,
  protein_g   double precision not null,
  carbs_g     double precision not null,
  fat_g       double precision not null,
  logged_at   timestamptz not null,
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  format      integer not null default 1,
  primary key (user_id, id)
);

-- --------------------------------- indexes --------------------------------
-- fetchChanged scans updated_at per user; children are fetched per parent.

create index if not exists profiles_updated_at_idx     on public.profiles            (user_id, updated_at);
create index if not exists exercises_updated_at_idx    on public.exercises           (user_id, updated_at);
create index if not exists routines_updated_at_idx     on public.routines            (user_id, updated_at);
create index if not exists workouts_updated_at_idx     on public.workouts            (user_id, updated_at);
create index if not exists body_metrics_updated_at_idx on public.body_metrics        (user_id, updated_at);
create index if not exists foods_updated_at_idx        on public.foods               (user_id, updated_at);
create index if not exists food_logs_updated_at_idx    on public.food_logs           (user_id, updated_at);
create index if not exists food_logs_day_idx           on public.food_logs           (user_id, day_key);
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
alter table public.body_metrics        enable row level security;
alter table public.foods               enable row level security;
alter table public.food_logs           enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'exercises', 'exercise_muscle_map',
    'routines', 'routine_exercises', 'workouts', 'workout_sets',
    'body_metrics', 'foods', 'food_logs'
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
