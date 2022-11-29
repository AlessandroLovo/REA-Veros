#!/bin/bash
folder="__test__/test_veros"

mkdir -p $folder

sbatch $@ veros_batch_restart.sh 5 $folder/e1 __test__/example.restart.h5