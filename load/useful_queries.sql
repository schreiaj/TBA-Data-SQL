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
-- I only have 2017 events loaded, so only doing 2017 for now.
SELECT ARRAY_AGG(events.event_name) as name,
  ARRAY_AGG(events.event_code) as code,
  EXTRACT(WEEK FROM date_start)-8 week,
  SUM(capacity_total) as capacity,
  COALESCE(SUM(teams.team_count),0) as nearby_teams,
  SUM(capacity_total) < COALESCE(SUM(teams.team_count),0) as full
FROM events
LEFT OUTER JOIN (SELECT count(teamid) AS team_count,
    (SELECT event_code FROM events WHERE countryCode='US' AND event_season=2017 AND event_subtype_moniker = 'Regional' OR event_subtype_moniker='District Event' ORDER BY teams.location <#> events.location LIMIT 1) AS event_code
  FROM teams
  WHERE country = 'US'
  GROUP BY event_code
  ORDER BY team_count DESC
  ) AS teams
ON teams.event_code = events.event_code
WHERE countryCode='US' AND event_season=2017 AND event_subtype_moniker = 'Regional' OR event_subtype_moniker='District Event'
GROUP BY event_address1, date_start
ORDER BY nearby_teams DESC
LIMIT 50;
