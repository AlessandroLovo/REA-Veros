#!/bin/bash

max_simultaneous_jobs=3

for i in {1..10} ; do
    jobID=$((i % $max_simultaneous_jobs))
    echo $jobID
    sbatch --wait --job-name=tRsing$jobID --dependency=singleton test_script.sh $i &
    # . test_script.sh $i &
done
wait
date
echo "all jobs finished"
