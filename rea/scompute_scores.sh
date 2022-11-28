#!/bin/bash -l
#
#SBATCH --time=03:00:00
#SBATCH --nodes=1

python compute_scores.py $@