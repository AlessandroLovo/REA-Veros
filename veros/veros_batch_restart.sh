#!/bin/bash -l
#
#SBATCH --time=23:59:59
#SBATCH --constraint=v1
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive


###export OMP_NUM_THREADS=1

echo "First arg: $1"
echo "Second arg: $2"
echo "Third arg: $3"

mkdir -p $1

veros resubmit -i ./$1/$2 -n 1 -l 3110400000 -c "srun --mpi=pmi2 -- python global_flexible.py -b numpy -v debug -n 6 2 -s restart_input_filename s720ur2b.0$3.restartP.h5" 

#--callback "sbatch veros_batch.sh"
# 3110400000 -> 100 years
