#!/bin/bash

./download_segments.sh # downloads segments in tmp/segments4

mv ../segments4 tmp/segments4_old && mv tmp/segments4 ../segments4

rm -rf tmp
