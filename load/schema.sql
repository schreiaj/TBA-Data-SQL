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


DROP TABLE raw_teams CASCADE;

CREATE TABLE raw_teams (
  team_number_yearly varchar,
  team_name_calc varchar,
  team_nickname varchar,
  team_city varchar,
  team_stateprov varchar,
  team_postalcode varchar,
  profile_year int,
  fk_program_seasons varchar,
  team_rookieyear int,
  team_web_url varchar,
  team_country varchar,
  countryCode varchar,
  team_type varchar,
  program_code_display varchar,
  program_name varchar,
  lat float,
  lon float
);

DROP TABLE raw_events CASCADE;

CREATE TABLE raw_events(
  event_name varchar,
  event_name_analyzed varchar,
  event_code varchar,
  fk_program_seasons varchar,
  event_subtype varchar,
  event_subtype_moniker varchar,
  event_type varchar,
  event_venue varchar,
  event_venue_sort varchar,
  event_venue_analyzed varchar,
  event_stateprov varchar,
  event_country varchar,
  event_city varchar,
  event_address1 varchar,
  event_address2 varchar,
  date_end date,
  date_start date,
  event_postalcode varchar,
  event_season int,
  capacity_total int,
  event_web_url varchar,
  flag_bag_and_tag_event boolean,
  program_code_display varchar,
  program_name varchar,
  flag_display_in_vims boolean,
  ff_event_type_sort_order varchar,
  countryCode varchar,
  open_capacity int,
  event_fee_currency varchar,
  hotel_document varchar,
  id varchar,
  lat float,
  lon float,
  event_venue_room varchar,
  event_fee_base varchar,
  community_event_contact_name_first varchar,
  community_event_contact_name_last varchar,
  community_event_contact_email varchar
);

-- Create MATERIALIZED VIEW to make it look like a table, far easier to refresh though

CREATE MATERIALIZED VIEW teams AS
  SELECT
    CONCAT('frc', team_number_yearly) AS teamId,
    team_number_yearly as number,
    profile_year as mostrecentyear,
    team_rookieyear as rookieYear,
    ST_POINT(lon, lat) as location,
    program_name as sponsors,
    team_nickname as nickname,
    countryCode as country
  FROM raw_teams
;

CREATE MATERIALIZED VIEW events AS
  SELECT
    *,
    st_point(lon, lat) as location
  FROM raw_events;

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
