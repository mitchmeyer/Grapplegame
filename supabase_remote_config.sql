-- Grapple remote configuration
-- Run this in Supabase SQL Editor once. After that, edit the JSON value to change
-- feed behavior, feature flags, hidden game types, point values, and Create routing
-- without requiring users to update the iOS app or web app shell.

create table if not exists public.remote_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.remote_config enable row level security;

drop policy if exists "Remote config is public readable" on public.remote_config;
create policy "Remote config is public readable"
on public.remote_config
for select
using (enabled = true);

drop trigger if exists remote_config_set_updated_at on public.remote_config;
drop function if exists public.set_remote_config_updated_at();
create function public.set_remote_config_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger remote_config_set_updated_at
before update on public.remote_config
for each row execute function public.set_remote_config_updated_at();

insert into public.remote_config (key, value, enabled)
values (
  'app',
  '{
    "features": {
      "offlineFeed": true,
      "create": true,
      "aiCreate": true,
      "challenges": true,
      "rankings": true,
      "profile": true,
      "admin": true
    },
    "games": {
      "disabledFamilies": ["Go Capture"],
      "disabledCategories": [],
      "disabledIds": [],
      "enabledFamilies": [],
      "allowLegacyGeneratedGames": false,
      "remoteOverridesLocal": true
    },
    "feed": {
      "initialBatch": 24,
      "nextBatch": 18,
      "refillDistancePx": 900,
      "noBackToBackFamily": true,
      "scoring": {
        "difficultyFit": 16,
        "exactDifficultyBonus": 4,
        "difficultyMissPenalty": 7,
        "categoryAffinityWeight": 0.8,
        "likedFamilyWeight": 2.5,
        "likedCategoryWeight": 1.2,
        "maxLikeBoost": 8,
        "dislikedFamilyWeight": 4,
        "dislikedCategoryWeight": 2,
        "maxDislikePenalty": 12,
        "strongFamilyRankWeight": 1.8,
        "weakFamilyRankWeight": 1.8,
        "unseenFamilyBoost": 5,
        "explorationWeight": 1.2,
        "maxCategoryConfidence": 4,
        "immediateRepeatPenalty": 30,
        "recentRepeatPenalty": 8,
        "savedBoost": 4,
        "exactLikeBoost": 5,
        "exactDislikePenalty": 10,
        "corePuzzleBoost": 3,
        "randomJitter": 2.5
      }
    },
    "points": {
      "correctScoreThreshold": 700,
      "scoreDivisor": 10,
      "hintPenalty": 10
    },
    "create": {
      "functionName": "create-game",
      "requireAuth": true
    },
    "timedFamilies": ["Memory Grid", "Word Scramble"]
  }'::jsonb,
  true
)
on conflict (key) do update
set value = excluded.value,
    enabled = excluded.enabled,
    updated_at = now();
