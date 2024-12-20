#!/bin/bash

cat queries.sql | while read -r query; do
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches

    echo "$query";
    psql -U username -h endpoint -p 5439 -d dev -t -c '\timing' -c "$query" | grep 'Time'
done;