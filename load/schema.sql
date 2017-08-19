DROP TABLE raw_matches;

CREATE TABLE raw_matches (
  matchId varchar,
  red1 varchar,
  red2 varchar,
  red3 varchar,
  blue1 varchar,
  blue2 varchar,
  blue3 varchar,
  redScore int,
  blueScore int
);

CREATE MATERIALIZED VIEW matches AS (
  SELECT
    matchid,
    metadata[1] AS year,
    metadata[2] AS event,
    metadata[3] AS level,
    metadata[4]  AS match,
    array[red1, red2, red3] as redTeams,
    array[blue1, blue2, blue3] as blueTeams,
    array[red1, red2, red3, blue1, blue2, blue3] as allTeams,
    CASE WHEN (redScore > blueScore) THEN array[red1, red2, red3]
      WHEN (blueScore > redScore) THEN array[blue1, blue2, blue3]
      ELSE null
    END
    as winner
  FROM (
    SELECT matchid,red1, red2, red3, blue1, blue2, blue3, redScore, blueScore, regexp_matches(matchid, '([0-9]{4})(.*?)_(.*)(m[0-9]+)') AS metadata
    FROM raw_matches) AS data
);


DROP TABLE raw_teams;

CREATE TABLE raw_teams (
  district varchar,
  locale varchar,
  location varchar,
  number varchar,
  related varchar,
  mostRecentYear varchar,
  rookieYear varchar,
  pos varchar,
  accuratePos boolean,
  schoolName varchar,
  sponsors varchar,
  notes varchar,
  x varchar
);

-- Create MATERIALIZED VIEW to make it look like a table, far easier to refresh though

CREATE MATERIALIZED VIEW teams AS
  SELECT
    CONCAT('frc', number) AS teamId,
    number,
    string_to_array(related, ',') AS related,
    mostRecentYear,
    rookieYear,
    CASE WHEN pos SIMILAR TO '(\-?\d+(\.\d+)?),\s*(\-?\d+(\.\d+)?)' THEN st_pointfromtext(concat('POINT(',replace(pos, ',', ''),')'))
      ELSE null
    END AS location,
    accuratePos,
    schoolName,
    sponsors,
    CASE WHEN district = '#N/A' THEN null ELSE district END AS district
  FROM raw_teams
  WHERE number IS NOT NULL
;


-- Now into win/loss data

CREATE VIEW most_wins AS
  WITH teams AS (
    SELECT unnest(winner) AS team
    FROM matches
  )
  SELECT count(1) AS wins, team
  FROM teams
  GROUP BY team
  ORDER BY wins DESC;

CREATE VIEW most_plays AS
  WITH teams AS (
    SELECT unnest(allTeams) AS team
    FROM matches
  )
  SELECT count(1) AS plays, team
  FROM teams
  GROUP BY team
  ORDER BY plays DESC;
