#!/bin/bash

out_dir="misc/segments4"

mkdir -p "$out_dir"

curl -s http://brouter.de/brouter/segments4/ | \
  grep -oE "[EW][0-9]+_[NS][0-9]+\.rd5" | \
  sort -u > /tmp/segments.txt

SECONDS=0

cat /tmp/segments.txt | xargs -I{} -P8 bash -c 'echo "Downloading: {}"; curl -s --remote-time -o "'"$out_dir"'/{}" "http://brouter.de/brouter/segments4/{}"'

echo "All segments downloaded to $out_dir in ${SECONDS}s"
rm /tmp/segments.txt
