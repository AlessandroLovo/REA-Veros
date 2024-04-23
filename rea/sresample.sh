#!/bin/bash
#
#SBATCH --time=01:00:00
#SBATCH --nodes=1

python resample.py "$@"