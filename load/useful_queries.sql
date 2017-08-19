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
