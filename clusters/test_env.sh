#!/bin/bash -l
#
#SBATCH --output=__test__/test_env.out
#SBATCH --error=__test__/test_env.err
#SBATCH --time=00:00:10

echo "$HOSTNAME"
date
echo
module list

python --version
which python
echo
veros --version
echo
veros resubmit --help