#!/bin/bash

out_dir="../segments4_diff"

mkdir -p $out_dir

find $out_dir -type f -mtime +10 -delete

SECONDS=0

folders=( `curl http://brouter.de/brouter/segments4/diff/ --silent | grep "[EW][0-9]*_[NS][0-9]*"  -o | uniq` )
> diffs

for folder in "${folders[@]}"
do
    mkdir -p "$out_dir/$folder"
    files=( `curl "http://brouter.de/brouter/segments4/diff/$folder/" --silent | grep "[a-z0-9]*\.df5" -o | uniq` )
    for file in "${files[@]}"
    do
        if [ ! -s "$out_dir/$folder/$file" ]; then # only download files that we don't already have
            echo "$folder/$file" >> diffs
        fi
    done
done

<diffs xargs -I{} -P8 curl "http://brouter.de/brouter/segments4/diff/{}" --remote-time --output "$out_dir/{}" --silent

rm diffs

echo "All segments diff downloaded in ${SECONDS}s"
