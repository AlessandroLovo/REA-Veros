#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --ntasks=12
# The two following directives have been moved into the defaults of clusters psmn and hpc as lorenz does not support cpu binding
##SBATCH --cpus-per-task=1
##SBATCH --threads-per-core=1

# new architecture:
# $1: time in years
# $2: prefix
# $3: restart (init) file. If not provided it is $2-init.h5

###export OMP_NUM_THREADS=1

if [[ -z "$REA_SRUN_MPI_ENABLED" ]] ; then
    echo "REA_SRUN_MPI_ENABLED env variable is not set" >&2
    return 1
    exit 1
elif $REA_SRUN_MPI_ENABLED ; then
    veros_mpi_cmd="srun --mpi=pmi2 --"
else
    veros_mpi_cmd="mpirun -np 12"
fi

if [[ -z $3 ]] ; then
    init_file="$2-init.h5"
else
    init_file="$3"
fi

T=$(($1*31104000))

echo Starting: $(date)
veros resubmit -i $2 -n 1 -l $T -c "$veros_mpi_cmd python ../veros-temp-noise-old/global_flexible.py -b numpy -v debug -n 6 2 -s restart_input_filename $init_file" 
echo Done: $(date)

#--callback "sbatch veros_batch.sh"
# 3110400000 -> 100 years
