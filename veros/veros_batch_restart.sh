#!/bin/bash -l
#
#SBATCH -p aegir
#SBATCH -A ocean
#SBATCH --job-name=R$1
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

# load only the modules used for veros
ml purge
ml load PrgEnv-gnu/2020 hdf5-parallel/1.10.7_mvapich2.3.4 h5py/2.10.0_mvapich2.3.4_py3.8.6 mvapich/2.3.4 mpi4py/3.0.3_mvapich2.3.4_py3.8.6 petsc/3.13.6_real_mvapich2.3.4 petsc4py/3.13.0_mvapich2.3.4_py3.8.6 python/3.8.6 veros/171220_py3.8.6
ml list

mkdir -p $1

veros resubmit -i ./$1/$2 -n 1 -l 3110400000 -c "srun --mpi=pmi2 -- python global_flexible.py -b numpy -v debug -n 6 2 -s restart_input_filename s720ur2b.0$3.restartP.h5" 

#--callback "sbatch veros_batch.sh"
# 3110400000 -> 100 years
