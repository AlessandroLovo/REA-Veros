#!/bin/bash

srun_mpi=true
partition="aegir"
account="ocean"
directives="--constraint=v1"
dynamics_directives="--exclusive --time=23:59:59"