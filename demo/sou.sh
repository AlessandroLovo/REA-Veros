#!/bin/bash
#
#SBATCH --time=00:00:10
#SBATCH --nodes=1

script_dir=$(dirname $0)

python $script_dir/ou.py "$@"