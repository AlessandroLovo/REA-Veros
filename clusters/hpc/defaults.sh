#!/bin/bash

srun_mpi=true
partition="aegir"
account="ocean"
directives="--constraint=v1"
dynamics_directives="--exclusive --time=23:59:59 --cpus-per-task=1 --threads-per-core=1"