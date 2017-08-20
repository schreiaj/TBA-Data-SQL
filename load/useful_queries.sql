-- Compute win pct for teams with more than 30 matches played

SELECT
  plays.team,
  CAST(wins.wins AS FLOAT)/plays.plays*100.0 as win_pct,
  plays.plays as matches,
  wins.wins as match_wins
FROM most_plays AS plays
JOIN most_wins AS wins
  ON wins.team = plays.team
WHERE plays.plays > 30
ORDER BY win_pct DESC
LIMIT 25;

-- Compute "winningest" ie who has won the most matches
SELECT team, wins
FROM most_wins
ORDER BY wins DESC
LIMIT 25;

-- Compute "loosingest" team. ie who has won the fewest
-- Caveat - in > 30 matches
SELECT
  plays.team,
  CAST(wins.wins AS FLOAT)/plays.plays*100.0 as win_pct,
  plays.plays as matches,
  wins.wins as match_wins
FROM most_plays AS plays
JOIN most_wins AS wins
  ON wins.team = plays.team
WHERE plays.plays > 30
ORDER BY win_pct
LIMIT 25;


-- Compute the nearest regional for all teams competing in regionals
-- I only have 2016 teams loaded, so only doing 2016 for now. 
SELECT count(teamid) AS team_count,
  (SELECT key FROM events WHERE year='2016' AND event_type='0' ORDER BY teams.location <#> events.location LIMIT 1) AS nearest_event,
  ARRAY_AGG(teamid)
FROM teams
WHERE mostrecentyear = '2016'
  AND location is not null
  AND rookieyear is not null
  AND district is null
GROUP BY nearest_event
ORDER BY team_count DESC;
