#!/bin/bash -l
#
#SBATCH -p aegir
#SBATCH -A ocean
#SBATCH --job-name=R$1
#SBATCH --time=00:02:00
#SBATCH --constraint=v1
#SBATCH --nodes=1


# these options are ignored

#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive

echo "Received argument $1"
sleep 10
echo "Done dealing with argument $1"