find ../data/events -type f -name "*_matches.csv" | while read line; do
  echo "\\\copy matches FROM $line WITH (FORMAT csv);"
done
