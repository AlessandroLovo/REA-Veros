#!/bin/bash -l
#
#SBATCH --time=00:30:00
#SBATCH --constraint=v1
#SBATCH --nodes=1

python resample.py $@