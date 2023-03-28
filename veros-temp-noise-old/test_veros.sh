#!/bin/bash

if [[ -z $SRUN_MPI_ENABLED ]] ; then
    echo "Please export SRUN_MPI_ENABLED either to true (use srun) or false (use mpirun)"
    return 1
    exit 1
fi

folder="__test__/test_veros"

mkdir -p $folder

sbatch -o $folder/v.out -e $folder/v.err "$@" veros_batch_restart.sh 5 $folder/e1 __test__/example.restart.h5