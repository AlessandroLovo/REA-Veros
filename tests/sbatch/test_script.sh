#!/bin/bash -l
#
#SBATCH --time=00:00:12
#SBATCH --nodes=1



# these options are ignored

#SBATCH -p aegir
#SBATCH -A ocean
#SBATCH --constraint=v1
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive

date
echo "Received argument $1"
sleep 10
date
echo "Done dealing with argument $1"
