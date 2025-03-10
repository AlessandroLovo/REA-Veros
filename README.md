# REA-Veros

Running the GKTL rare event algorithm on the Versatile Ocean Simulator (Veros)

## folder structure

1. `rea`: code with the rare event algorithm, divided in several scripts and quite versatile
2. `veros`: code for running the veros ocean model, mainly on a cluster
3. `clusters`: contains a subfolder for each cluster with useful scripts.
3. `demo`: benchmark of the rare event algorithm on simple 1D dynamics like the Ornstein-Uhlenbeck process or a simple double well potential
4. `tests`: various simple tests of the components of the code, there shouldn't be anything interesting in there
5. `orig`: original version of the code by Johannes Lohmann
6. `general_purpose`: submodule with general purpose functions

## code structure

The main script is `rea/rea.sh` and is the one coordinating everything: it supports different dynamics besides veros and can be run on clusters that use `slurm`. To do so go inside the `rea` directory and run

```
. rea.sh [options]
```

where the options are:

```
-m|--model                  name of the folder with the model for the dynamics.
                            This folder has to be on the same level as the 'rea' directory
                            If the model folder contains a 'defaults.sh' script, it will be sourced,
                            setting default values for some of the following options
-i|--iterations             number of iterations of the algorithm
-k|--k                      selection strenght
-t|--timestep               timestep of the algorithm
-e|--ensemble-size          number of ensemble members

[-E|--initial-ensemble]     folder containing the initial ensemble, in particular init files for each ensemble member
[-I|--init-file]            single init file from which to generate the ensemble
[--init-ensemble-script]    script for generating an ensemble from a single init file

[-p|--prefix]               prefix for the run name
[-n|--name]                 full run name (overrides prefix)
[-r|--root|--root-folder]   parent of the run folder

[-d|--dynamics]             script for running the dynamics
[--cloning-script]          script for cloning trajectories
[--make-traj-script]        script for creating the trajectory of the observable used for computing the scores

[-j|--jobs]                 maximum number of simultaneously running ensemble members
[--cluster]                 if provided, name of the cluster on which to run. It must be also a folder inside the clusters directory
[--srun-mpi]                Use srun for mpi
[--no-srun-mpi]             Use mpirun for mpi
[-P|--partition]            partition in which to run
[-A|--account]              user account on the cluster
[--directives]              sbatch directives for every submitted job, enclose it in inverted commas
[--dynamics-directives]     sbatch directives applied only to jobs running the dynamics
[--no-modules]              do not handle modules
[--python-modules]          script that loads modules for python
[--dynamics-modules]        script that loads modules for the dynamics

[-b|--bot-token]            telegram bot token or file containing it
[-c|--chat-id]              telegram chat id to which to send the logging messages
[-l|--log-level]            telegram logging level

[--skip]                    start the run without asking for confirmation
```

Run the script without any option to visualize all possible options and their explanation.

Pseudocode:

```
# Initialize `nens` ensemble members and propagate them for the first timestep `T`
for i in {1..NITER} do
    # compute score of the previous iteration
    # resample initial conditions for the current iteration
    # propagate each ensemble member for `T`
done
```

## Run structure

Each run consists of a folder with a given name that contains the following:

1. `parameters.txt`: a file containing the information relative to the run.
2. `reconstructed.json`: a json file containing the backward reconstructed trajectories from the last iteration of the algorithm with their associated probabilities.
3. Iteration folders with names like `i0000`, `i0001`, ... Each one contains:

    1. `info.json`: json file containing the information of the current iteration.
    2. Ensemble members with prefix of the kind `e1` or `e01` depending on how many there are. Each one of them will have:
        1. an init file (e.g. `e01-init.h5`) containing the initial conditions of that member at the beginning of the current iteration
        2. a restart file (e.g. `e01.0000.restart.h5`) containing the initial conditions at the end of the current iteration
        3. a trajectory file (e.g. `e01-traj.npy`) containing the trajectory of the observable used for computing the score of the member in the current iteration. The file contains a numpy array with shape (N,2) where the first column is time and the second one is the value of the observable.
        4. Other output files of the model dynamics.

        In a minimal run you'll find only the trajectory file.

---

## Running a new model on a new cluster

If you want to use this repo to run a model different from veros, you will have to proceed as following.

If you only want to run on a new cluster skip this section and go to the next one.

### Setting up a new model

Let us suppose you want to run a model named `qwyn`. First you need to create a directory named `qwyn` on the same level of `rea`.

Inside folder `qwyn` you will put all your scripts for running the model, but in particular you'll need

1. A script for running a single ensemble member that accepts as input, in order:

    1. how long to run the simulation
    2. the prefix for output files
    3. (optional) the input file with initial conditions

    This script can contain a header with SBATCH directives and must produce as output a restart file, namely a file with the initial conditions necessary to continue the run where it ended.

    See as example `veros/veros_batch_restart.sh`

2. A script for extracting the observable of interest from an ensemble member. It has to accept as input the prefix that identifies the ensemble member, and it has to create a file `<prefix>-traj.npy` that saves a numpy array of shape (N,2) where the first column is the time during the current iteration and the second one is the value of the observable to compute the score.

    See as example `veros/make_traj.py`

3. (optional if your dynamics is already stochastic, mandatory if it is deterministic) A script for perturbing initial conditions. Input:

    1. The prefix of the original restart file (e.g. i0010/e01)
    2. The prefix for the destination init file (e.g. i0011/e12)

    See as example `veros/perturb_ic.py`

4. (optional) A script for generating an ensemble of initial conditions from a single init file. Input:

    1. The path to the init file
    2. The destination folder where to put all the new init files
    3. The number of ensemble members.

    This script may use the previous one for perturbing initial conditions.

    See as example `veros/make_ensemble.py`

5. (optional): `defaults.sh`: a script that sets default values for the environment variables used by `rea.sh`. If the same option is provided when running `rea.sh`, this one will override the one set by `defaults.sh`.

    See as an example `veros/defaults.sh`


### Setting up a new cluster

Inside the `clusters` directory, create a new folder with the name of your cluster (the name can be whatever you prefer, and it will be the one you need to provide to the option `--cluster` when you run `rea.sh`)

Inside this newly created directory put

1. A `modules` folder containing:
    1. `python.sh`: script that loads the modules necessary for running python
    2. for every model you want to run, a script `<model_name>.sh` that loads the modules for running that model

2. (optional) `defaults.sh`: script that sets cluster specific default values for the environment variables used by `rea.sh`. As for the model defaults, If you then provide a different value as option when you run `rea.sh`, this one will override the default one set by `defaults.sh`.

3. (optional) `init.sh`: Script for setting up the cluster when you log in. This is just for yourself, and it won't be used by the algorithm at any point.

As an example look at folder `clusters/psmn` and its content.

To see how to set up the environments for the veros model and the rare event algorithm look respectively at [setup-veros-env](veros/setup.md) and [setup-rea-env](rea/setup.md)