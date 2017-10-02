DROP TABLE IF EXISTS Airports;

CREATE TABLE Airports (
	AIRPORT_SEQ_ID varchar,
	AIRPORT_ID varchar,
	AIRPORT varchar,
	DISPLAY_AIRPORT_NAME varchar,
	DISPLAY_AIRPORT_CITY_NAME_FULL varchar,
	AIRPORT_WAC_SEQ_ID2 varchar,
	AIRPORT_WAC varchar,
	AIRPORT_COUNTRY_NAME varchar,
	AIRPORT_COUNTRY_CODE_ISO varchar,
	AIRPORT_STATE_NAME varchar,
	AIRPORT_STATE_CODE varchar,
	AIRPORT_STATE_FIPS varchar,
	CITY_MARKET_SEQ_ID varchar,
	CITY_MARKET_ID varchar,
	DISPLAY_CITY_MARKET_NAME_FULL varchar,
	CITY_MARKET_WAC_SEQ_ID2 varchar,
	CITY_MARKET_WAC varchar,
	LAT_DEGREES varchar,
	LAT_HEMISPHERE varchar,
	LAT_MINUTES varchar,
	LAT_SECONDS varchar,
	LATITUDE float,
	LON_DEGREES varchar,
	LON_HEMISPHERE varchar,
	LON_MINUTES varchar,
	LON_SECONDS varchar,
	LONGITUDE float,
	AIRPORT_START_DATE varchar,
	AIRPORT_THRU_DATE varchar,
	AIRPORT_IS_CLOSED boolean,
	AIRPORT_IS_LATEST boolean,
	X varchar
);

\copy airports from './airport-data.csv' with (FORMAT CSV, HEADER true)


DROP TABLE IF EXISTS Routes;
CREATE TABLE Routes (
	tbl VARCHAR  NOT NULL, 
	"Year" DECIMAL NOT NULL, 
	quarter BOOLEAN NOT NULL, 
	citymarketid_1 DECIMAL NOT NULL, 
	citymarketid_2 DECIMAL NOT NULL, 
	city1 VARCHAR NOT NULL, 
	city2 VARCHAR NOT NULL, 
	nsmiles DECIMAL NOT NULL, 
	passengers DECIMAL NOT NULL, 
	fare DECIMAL NOT NULL, 
	carrier_lg VARCHAR NOT NULL, 
	large_ms DECIMAL NOT NULL, 
	fare_lg DECIMAL NOT NULL, 
	carrier_low VARCHAR NOT NULL, 
	lf_ms DECIMAL NOT NULL, 
	fare_low DECIMAL NOT NULL
);

\copy routes from './route-fares.csv' with (FORMAT CSV, HEADER true)

DROP TABLE IF EXISTS raw_teams;

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

\copy raw_teams from ./teams_2018.csv with (FORMAT CSV, HEADER true)

DROP TABLE IF EXISTS raw_events;

CREATE TABLE raw_events (
	event_name VARCHAR, 
	event_name_analyzed VARCHAR, 
	event_code VARCHAR, 
	fk_program_seasons DECIMAL, 
	event_subtype VARCHAR, 
	event_subtype_moniker VARCHAR, 
	event_type VARCHAR, 
	event_venue VARCHAR, 
	event_venue_sort VARCHAR, 
	event_venue_analyzed VARCHAR, 
	event_stateprov VARCHAR, 
	event_country VARCHAR, 
	event_city VARCHAR, 
	event_address1 VARCHAR, 
	event_address2 VARCHAR, 
	date_end TIMESTAMP, 
	date_start TIMESTAMP, 
	event_postalcode VARCHAR, 
	event_season DECIMAL, 
	capacity_total DECIMAL, 
	event_web_url VARCHAR, 
	flag_bag_and_tag_event BOOLEAN, 
	program_code_display VARCHAR, 
	program_name VARCHAR, 
	flag_display_in_vims BOOLEAN, 
	ff_event_type_sort_order DECIMAL, 
	"countryCode" VARCHAR, 
	open_capacity DECIMAL, 
	event_fee_currency VARCHAR, 
	hotel_document VARCHAR, 
	id DECIMAL, 
	lat DECIMAL, 
	lon DECIMAL, 
	event_venue_room BOOLEAN, 
	event_fee_base BOOLEAN, 
	community_event_contact_name_first VARCHAR, 
	community_event_contact_name_last VARCHAR, 
	community_event_contact_email VARCHAR
);


\copy raw_teams from ./events_2018.csv with (FORMAT CSV, HEADER true)


-- Haversine Formula based geodistance in miles (constant is diameter of Earth in miles)
-- Based on a similar PostgreSQL function found here: https://gist.github.com/831833
-- Updated to use distance formulas found here: http://www.codecodex.com/wiki/Calculate_distance_between_two_points_on_a_globe
CREATE OR REPLACE FUNCTION public.geodistance(alat double precision, alng double precision, blat double precision, blng double precision)
  RETURNS double precision AS
$BODY$
SELECT asin(
  sqrt(
    sin(radians($3-$1)/2)^2 +
    sin(radians($4-$2)/2)^2 *
    cos(radians($1)) *
    cos(radians($3))
  )
) * 7926.3352 AS distance;
$BODY$
  LANGUAGE sql IMMUTABLE
  COST 100;
-- Source: https://gist.github.com/carlzulauf/1724506


-- Create a join table between airport and regional (let's us precompute this)
DROP TABLE IF EXISTS event_airport;
create table event_airport AS (select e.event_code, a.airport, geodistance(e.lat, e.lon, a.latitude, a.longitude) from raw_events e join airports a on 1=1 where a.airport_is_closed is false and a.airport_is_latest is true and event_subtype = 'Regional' );

-- Same deal for teams... Warning this one takes some time. 
DROP TABLE IF EXISTS team_airport;
create table team_airport AS (select t.team_number_yearly, a.airport, geodistance(t.lat, t.lon, a.latitude, a.longitude) from raw_teams t join airports a on 1=1 where a.airport_is_closed is false and a.airport_is_latest is true);


-- We're going to set up some indexes on the big table, make querying it suck a little less. 
-- Again, these will take a while to run. You can skip this step if you want but it genuinely makes playing with data tolerable
create index team_airport_team_idx ON team_airport (team_number_yearly);
create index team_airport_airport_idx ON team_airport (airport);
create index team_airport_geodistance_idx ON team_airport (geodistance);


