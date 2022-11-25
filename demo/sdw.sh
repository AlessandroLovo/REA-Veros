#!/bin/bash -l
#
#SBATCH --time=00:00:10
#SBATCH --nodes=1

python dw.py $@