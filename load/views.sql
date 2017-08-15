CREATE VIEW win_loss AS
  SELECT
    matchId,
    array[red1, red2, red3] as redTeams,
    array[blue1, blue2, blue3] as blueTeams,
    array[red1, red2, red3, blue1, blue2, blue3] as allTeams,
    redScore,
    blueScore,
    CASE WHEN (redScore > blueScore) THEN array[red1, red2, red3]
      WHEN (blueScore > redScore) THEN array[blue1, blue2, blue3]
      ELSE null
    END
    as winner
  FROM matches;

CREATE VIEW most_wins AS
  WITH teams AS (
    SELECT unnest(winner) AS team
    FROM win_loss
  )
  SELECT count(1) as wins, team
  FROM teams
  GROUP BY team
  ORDER BY wins DESC;

CREATE VIEW most_plays AS
  WITH teams AS (
    SELECT unnest(allTeams) AS team
    FROM win_loss
  )
  SELECT count(1) as plays, team
  FROM teams
  GROUP BY team
  ORDER BY plays DESC;
