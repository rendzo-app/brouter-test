#!/bin/bash

./download_segments_diff.sh # downloads diff directory in ../segments4_diff

mkdir -p tmp/segments4

java -cp ../../brouter-server/build/libs/brouter-1.7.7-all.jar btools.mapaccess.Rd5DiffApplier ../segments4 ../segments4_diff tmp/segments4

if [[ $(ls tmp/segments4 | wc -l) -ge 1130 ]]; then

    mv ../segments4 tmp/segments4_old && mv tmp/segments4 ../segments4

    rm -rf tmp

else

    rm -rf tmp

    ./reset_segments.sh

fi
