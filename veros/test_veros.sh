#!/bin/bash
folder="__test__/test_veros"

mkdir -p $folder

sbatch -o $folder/v.out -e $folder/v.err $@ veros_batch_restart.sh 5 $folder/e1 __test__/example.restart.h5