#!/bin/bash


for i in {1..5} ; do
    # sbatch --job-name=R$i test_script.sh $i
    . test_script.sh $i &
done
wait

echo "all jobs finished"