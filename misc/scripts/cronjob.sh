#!/bin/bash

./download_segments_diff.sh # downloads diff directory in tmp/diff

mkdir -p tmp/segments4

java -cp ../../brouter-server/build/libs/brouter-1.6.3-all.jar btools.mapaccess.Rd5DiffApplier ../segments4 ../segments4_diff tmp/segments4

mv ../segments4 tmp/segments4_old && mv tmp/segments4 ../segments4

rm -rf tmp
