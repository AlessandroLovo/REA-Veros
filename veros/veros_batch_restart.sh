#!/bin/bash -l
#
#SBATCH --time=23:59:59
#SBATCH --constraint=v1
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive

# new architecture:
# $1: time in years
# $2: prefix
# $3: restart (init) file. If not provided set a default restart file: TODO!

###export OMP_NUM_THREADS=1

# echo "First arg: $1"
# echo "Second arg: $2"
# echo "Third arg: $3"

if [[ -z $3 ]] ; then
    echo "default restart file not supported"
    return 1
else
    init_file="$3"
fi

T=$(($1*31104000))

veros resubmit -i $2 -n 1 -l $T -c "srun --mpi=pmi2 -- python global_flexible.py -b numpy -v debug -n 6 2 -s restart_input_filename $init_file" 

#--callback "sbatch veros_batch.sh"
# 3110400000 -> 100 years
