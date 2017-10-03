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
	quarter INT NOT NULL, 
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

-- There's something funky going on with events, I've been able to get it loaded using:

-- csvsql events_2018.csv --no-constraints --tables raw_events --db postgresql:///[dbname] --insert --overwrite

-- DROP TABLE IF EXISTS raw_events;

-- CREATE TABLE raw_events (
-- 	event_name VARCHAR, 
-- 	event_name_analyzed VARCHAR, 
-- 	event_code VARCHAR, 
-- 	fk_program_seasons DECIMAL, 
-- 	event_subtype VARCHAR, 
-- 	event_subtype_moniker VARCHAR, 
-- 	event_type VARCHAR, 
-- 	event_venue VARCHAR, 
-- 	event_venue_sort VARCHAR, 
-- 	event_venue_analyzed VARCHAR, 
-- 	event_stateprov VARCHAR, 
-- 	event_country VARCHAR, 
-- 	event_city VARCHAR, 
-- 	event_address1 VARCHAR, 
-- 	event_address2 VARCHAR, 
-- 	date_end TIMESTAMP, 
-- 	date_start TIMESTAMP, 
-- 	event_postalcode VARCHAR, 
-- 	event_season DECIMAL, 
-- 	capacity_total DECIMAL, 
-- 	event_web_url VARCHAR, 
-- 	flag_bag_and_tag_event BOOLEAN, 
-- 	program_code_display VARCHAR, 
-- 	program_name VARCHAR, 
-- 	flag_display_in_vims BOOLEAN, 
-- 	ff_event_type_sort_order DECIMAL, 
-- 	"countryCode" VARCHAR, 
-- 	open_capacity DECIMAL, 
-- 	event_fee_currency VARCHAR, 
-- 	hotel_document VARCHAR, 
-- 	id DECIMAL, 
-- 	lat DECIMAL, 
-- 	lon DECIMAL, 
-- 	event_venue_room BOOLEAN, 
-- 	event_fee_base BOOLEAN, 
-- 	community_event_contact_name_first VARCHAR, 
-- 	community_event_contact_name_last VARCHAR, 
-- 	community_event_contact_email VARCHAR
-- );


-- \copy raw_teams from ./events_2018.csv with (FORMAT CSV, HEADER true)


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
create table event_airport AS (select e.event_code, a.airport, geodistance(e.lat, e.lon, a.latitude, a.longitude) from raw_events e join airports a on 1=1 where a.airport_is_closed is false and a.airport_is_latest is true and event_subtype_moniker in ('Regional', 'District Event') );

-- Same deal for teams... Warning this one takes some time. 
DROP TABLE IF EXISTS team_airport;
create table team_airport AS (select t.team_number_yearly, a.airport, geodistance(t.lat, t.lon, a.latitude, a.longitude) from raw_teams t join airports a on 1=1 where a.airport_is_closed is false and a.airport_is_latest is true);


-- We're going to set up some indexes on the big table, make querying it suck a little less. 
-- Again, these will take a while to run. You can skip this step if you want but it genuinely makes playing with data tolerable
CREATE INDEX team_airport_team_idx ON team_airport (team_number_yearly);
CREATE INDEX team_airport_airport_idx ON team_airport (airport);
CREATE INDEX team_airport_geodistance_idx ON team_airport (geodistance);
CREATE INDEX event_airport_event_idx ON event_airport (event_code);
CREATE INDEX event_airport_airport_idx ON event_airport (airport);
CREATE INDEX event_airport_geodistance_idx ON event_airport (geodistance);

CREATE INDEX airports_city_market_id_idx ON airports (city_market_id);
CREATE INDEX raw_teams_team_idx ON raw_teams (team_number_yearly);

-- This is the route data we need 
-- It's massive so you have to download it yourself because it would make git cry:
-- https://www.transtats.bts.gov/DL_SelectFields.asp Just select "Prezipped File" and wait
DROP TABLE IF EXISTS fares;
CREATE TABLE fares(
	ItinID varchar
	,MktID varchar
	,MktCoupons varchar
	,Year int
	,Quarter int
	,OriginAirportID varchar
	,OriginAirportSeqID varchar
	,OriginCityMarketID varchar
	,Origin varchar
	,OriginCountry varchar
	,OriginStateFips varchar
	,OriginState varchar
	,OriginStateName varchar
	,OriginWac varchar
	,DestAirportID varchar
	,DestAirportSeqID varchar
	,DestCityMarketID varchar
	,Dest varchar
	,DestCountry varchar
	,DestStateFips varchar
	,DestState varchar
	,DestStateName varchar
	,DestWac varchar
	,AirportGroup varchar
	,WacGroup varchar
	,TkCarrierChange varchar
	,TkCarrierGroup varchar
	,OpCarrierChange varchar
	,OpCarrierGroup varchar
	,RPCarrier varchar
	,TkCarrier varchar
	,OpCarrier varchar
	,BulkFare float
	,Passengers varchar
	,MktFare float
	,MktDistance float
	,MktDistanceGroup varchar
	,MktMilesFlown float
	,NonStopMiles varchar
	,ItinGeoType varchar
	,MktGeoType varchar
	,xx varchar
);

-- \copy fares from Origin_and_Destination_Survey_DB1BMarket_2017_1.csv with (FORMAT CSV, HEADER true) 

CREATE INDEX fares_origin_idx ON fares (origin);
CREATE INDEX fares_dest_idx ON fares (dest);
CREATE INDEX fares_mktfare_idx ON fares (MktFare);

-- To grab the closeset airport is pretty easy

-- select airport from team_airport RIGHT JOIN fares r on r.origin = airport where team_number_yearly = '27' order by geodistance asc limit 1;

-- select airport from event_airport RIGHT JOIN fares r on r.origin = airport where event_code='CAAV' order by geodistance asc limit 1;


-- This computes the avg fare from the nearest airport to the team and to the event. 
-- select Origin, Dest, avg(MktFare) from fares where Origin=(select airport from team_airport RIGHT JOIN fares r on r.origin = airport where team_number_yearly = '1056' order by geodistance asc limit 1) AND dest=(select airport from event_airport RIGHT JOIN fares r on r.origin = airport where event_code='HIHO' order by geodistance asc limit 1) group by origin, dest;

CREATE OR REPLACE FUNCTION public.flight_cost(team text, event_code text) RETURNS RECORD AS $$
	DECLARE 
	  ret RECORD;
	BEGIN 
		select Origin, Dest, avg(MktFare) from fares where Origin=(select airport from team_airport RIGHT JOIN fares r on r.origin = airport where team_number_yearly = team order by geodistance asc limit 1) AND dest=(select airport from event_airport RIGHT JOIN fares r on r.origin = airport where event_code=event_code order by geodistance asc limit 1) group by origin, dest INTO ret;
	RETURN ret
	END;
$$
  LANGUAGE sql IMMUTABLE
  COST 100;


