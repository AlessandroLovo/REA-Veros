#!/bin/bash

script_dir=$(dirname ${BASH_SOURCE[0]})

dynamics_script="$script_dir/veros_batch_restart.sh"
cloning_script="$script_dir/../veros/perturb_ic.py" # script that clones a trajectory, eventually perturbing initial conditions
make_traj_script="$script_dir/../veros/make_traj.py"
init_ensemble_script="$script_dir/../veros/make_ensemble.py"
msj=5