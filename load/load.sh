cat config_postgis.sql
cat schema.sql

# find ../data/events -type f -name "*_matches.csv" -exec cat {} \;
# MIGHT end up being a less bad way to do it. Needs research
find ../data/events -type f -name "*_matches.csv" | while read line; do
  echo "\\\copy raw_matches FROM $line WITH (FORMAT csv);"
done

echo "\\\copy raw_teams from ../local_data/teams_2018.csv with (FORMAT CSV, HEADER true)"
echo "\\\copy raw_events from ../local_data/events_2017.csv WITH (FORMAT CSV, HEADER true)"
echo "REFRESH MATERIALIZED VIEW teams;"
echo "REFRESH MATERIALIZED VIEW matches;"
