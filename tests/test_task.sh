#!/bin/bash
#
#SBATCH --output=__test__/test.out
#SBATCH --error=__test__/test.err
#SBATCH --time=00:00:10

echo "$HOSTNAME"
date
echo
echo "Sleeping"
sleep 1
echo "DONE"