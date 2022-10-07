#!/bin/bash -l
#
#SBATCH --time=01:00:00
#SBATCH --constraint=v1
#SBATCH --nodes=1

python compute_scores.py $@