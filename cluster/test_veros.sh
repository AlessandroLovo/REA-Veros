#!/bin/bash
#
#SBATCH --output=__test__/test_veros.out
#SBATCH --error=__test__/test_veros.err
#SBATCH --time=00:00:10

echo "$HOSTNAME"
date
echo
python --version
veros --version