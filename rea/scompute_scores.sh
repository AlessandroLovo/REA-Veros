#!/bin/bash -l
#
#SBATCH --time=00:10:00
#SBATCH --constraint=v1
#SBATCH --nodes=1

python compute_scores.py $@