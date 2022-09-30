#!/bin/bash -l
#
#SBATCH -A ocean
#SBATCH --time=00:00:10
#SBATCH --constraint=v1
#SBATCH --nodes=1

python ou.py $1 $2 $3