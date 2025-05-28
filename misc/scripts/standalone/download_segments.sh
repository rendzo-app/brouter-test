#!/bin/bash

out_dir="misc/segments4"

curl http://brouter.de/brouter/segments4/ --silent | grep "[EW][0-9]*_[NS][0-9]*\.rd5" -o | uniq > segments

mkdir -p $out_dir

SECONDS=0

<segments xargs -I{} -P8 curl "http://brouter.de/brouter/segments4/{}" --remote-time --output "$out_dir/{}" --silent

echo "All segments downloaded in ${SECONDS}s"

rm segments
