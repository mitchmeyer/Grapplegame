-- Canonical chess IDs for Grapple.
-- Run this in Supabase SQL Editor if any database rows still use chess1, chess2, ...
-- The canonical public game IDs are ch1, ch2, ch3, ... ch20.

alter table if exists public.games
  add column if not exists game_key text;

create unique index if not exists games_game_key_unique
  on public.games (game_key)
  where game_key is not null;

do $$
declare
  rel_name text;
begin
  if to_regclass('public.games') is not null then
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'games'
        and column_name = 'id'
        and data_type in ('text', 'character varying', 'character')
    ) then
      execute $sql$
        update public.games
        set id = regexp_replace(id, '^chess([0-9]+)$', 'ch\1', 'i')
        where id ~* '^chess[0-9]+$'
      $sql$;
    end if;

    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'games'
        and column_name = 'slug'
    ) then
      execute $sql$
        update public.games
        set slug = regexp_replace(slug, '^chess([0-9]+)$', 'ch\1', 'i')
        where slug ~* '^chess[0-9]+$'
      $sql$;

      execute $sql$
        update public.games
        set game_key = regexp_replace(coalesce(game_key, slug), '^chess([0-9]+)$', 'ch\1', 'i')
        where coalesce(game_key, slug) ~* '^chess[0-9]+$'
      $sql$;
    else
      execute $sql$
        update public.games
        set game_key = regexp_replace(game_key, '^chess([0-9]+)$', 'ch\1', 'i')
        where game_key ~* '^chess[0-9]+$'
      $sql$;
    end if;
  end if;

  foreach rel_name in array array['game_plays', 'saved_games', 'challenges', 'ai_game_drafts'] loop
    if to_regclass('public.' || rel_name) is not null
      and exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = rel_name
          and column_name = 'game_id'
          and data_type in ('text', 'character varying', 'character')
      )
    then
      execute format(
        'update public.%I set game_id = regexp_replace(game_id, %L, %L, %L) where game_id ~* %L',
        rel_name,
        '^chess([0-9]+)$',
        'ch\1',
        'i',
        '^chess[0-9]+$'
      );
    end if;
  end loop;
end $$;
