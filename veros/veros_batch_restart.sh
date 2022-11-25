#!/bin/bash -l
#
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1

# new architecture:
# $1: time in years
# $2: prefix
# $3: restart (init) file. If not provided it is $2-init.h5

###export OMP_NUM_THREADS=1

if [[ -z $3 ]] ; then
    init_file="$2-init.h5"
else
    init_file="$3"
fi

T=$(($1*31104000))

veros resubmit -i $2 -n 1 -l $T -c "srun --mpi=pmi2 -- python ../veros/global_flexible.py -b numpy -v debug -n 6 2 -s restart_input_filename $init_file" 

#--callback "sbatch veros_batch.sh"
# 3110400000 -> 100 years
