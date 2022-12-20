#!/bin/bash

##### Define useful functions #####
parse_command_line () { # you should give it "$@"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                model="$2"
                shift
                shift
                ;;
            -i|--iterations) # number of iterations
                NITER="$2"
                shift
                shift
                ;;
            -d|--dynamics) # dynamics script
                dynamics_script="$2"
                shift
                shift
                ;;
            -k|--k) # selection strength
                k="$2"
                shift
                shift
                ;;
            --cloning-script) # cloning script
                cloning_script="$2"
                shift
                shift
                ;;
            -t|--timestep) # resampling timestep
                T="$2"
                shift
                shift
                ;;
            -e|--ensemble-size) # number of ensemble members
                nens="$2"
                shift
                shift
                ;;
            --make-traj-script) # script that creates the trajectory of the observable used to compute the scores
                make_traj_script="$2"
                shift
                shift
                ;;
            -E|--initial-ensemble) # folder where the initial ensemble is, either fully propagated or only with the init files
                initial_ensemble_folder="$2"
                shift
                shift
                ;;
            -I|--init-file) # common init file for the first iteration
                init_file="$2"
                shift
                shift
                ;;
            --init-ensemble-script) # script for creating an ensemble from a single init file
                init_ensemble_script="$2"
                shift
                shift
                ;;
            -p|--prefix) # prefix in naming the run folder
                p="$2"
                shift
                shift
                ;;
            -n|--name) # name of the run folder: overrides prefix
                name="$2"
                shift
                shift
                ;;
            -r|--root|--root-folder) # parent of the run folder
                root_folder="$2"
                shift
                shift
                ;;
            -j|--jobs) # maximum number of simultaneous ensemble members running
                msj="$2"
                shift
                shift
                ;;
            --cluster) # run on a cluster
                cluster=true
                cluster_name="$2"
                shift
                shift
                ;;
            --srun-mpi)
                srun_mpi=true
                shift
                ;;
            --no-srun-mpi)
                srun_mpi=false
                shift
                ;;
            -P|--partition) # cluster partition
                partition="$2"
                shift
                shift
                ;;
            -A|--account) # cluster account
                account="$2"
                shift
                shift
                ;;
            --directives) # general extra sbatch directives
                directives="$2"
                shift
                shift
                ;;
            --dynamics-directives) # sbatch directives specific only for the dynamics script
                dynamics_directives="$2"
                shift
                shift
                ;;
            --no-modules) # disable loading and purging of modules
                handle_modules=false
                shift # past argument
                ;;
            --python-modules) # script that loads the modules required for running python on the cluster
                python_modules="$2"
                shift
                shift
                ;;
            --dynamics-modules) # script that loads the modules required for running the dynamics on the cluster
                dynamics_modules="$2"
                shift
                shift
                ;;
            -b|--bot-token) # telegram bot authorization token
                TBT="$2"
                shift
                shift
                ;;
            -c|--chat-id) # telegram chat ID to whom to send the logs
                CHAT_ID="$2"
                shift
                shift
                ;;
            -l|--log-level) # telegram logging level
                TLL="$2"
                shift
                shift
                ;;
            --skip) # skip summary of parameters and confirmation
                proceed=true
                shift
                ;;
            -*|--*)
                echo "Unknown option $1"
                return 1
                exit 1
                ;;
            *)
                POSITIONAL_ARGS+=("$1") # save positional arg
                shift
                ;;
        esac
    done
}

usage () {
echo "Usage: source this script from its directory:

    . rea.sh [options]

Positional arguments are ignored. The options are the following (the ones enclosed in [] are optional)

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
    
    "
}

summary () {
    if [[ -z ${initial_ensemble_folder} ]] ; then
        echo "Starting a new run in folder $folder"
        if [[ -z ${init_file} ]] ; then
            echo "    from scratch"
        else
            echo "    from $init_file"
            if [[ ! -z ${init_ensemble_script} ]] ; then
                echo "    creating the initial ensemble with $init_ensemble_script"
            fi
        fi
    else
        echo "Continuing run in folder $folder"
        echo "    from iteration $i0"
    fi
    echo "Algorithm will be run with"
    echo "    NITER = $NITER"
    echo "    nens  = $nens"
    echo "    t     = $T"
    echo "    k     = $k"
    echo "Model = $model"
    echo "    dynamics_script = $dynamics_script"
    echo "    cloning_script = $cloning_script"
    echo "    make_traj_script = $make_traj_script"
    echo "Maximum simultaneous ensemble members: $msj"
    if $cluster ; then
        echo "Running on cluster $cluster_name"
        echo "    with sbatch directive:"
        echo "        $sbatch_script"
        if [[ ! -z ${dynamics_directives} ]] ; then
            echo "    with the extra directives for the dynamics:"
            echo "        $dynamics_directives"
        fi
        if $handle_modules ; then
            echo "    python_modules   : $python_modules"
            echo "    dynamics_modules : $dynamics_modules"
        else
            echo "    without handling modules"
        fi
        if $srun_mpi ; then
            echo "    using srun --mpi for parallelization"
        else
            echo "    using mpirun for parallelization"
        fi
    else
        echo "Running on the local machine"
    fi
    echo
    echo "Telegram logging level: $TLL"
    echo
    echo
}

load_modules () {
    if [[ ! -z $1 ]] ; then
        module purge
        . $1
        module list
    else
        python log2telegram.py \""No module loading script provided: skipping"\" 30 $TARGS 
    fi
}

# run the dynamics for one timestep of the algorithm
propagate () { # accepts as only argument the optional init file. If not provided, the script will look for init files for each ensemble members
    date >> $dyn_log
    echo "$HOSTNAME: Starting dynamics" >> $dyn_log
    if $cluster ; then
        if $handle_modules ; then
            load_modules $dynamics_modules # load modules for running the dynamics
        fi

        for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do # 0-pad the number of the ensemble member
                jobID=$((10#$ens % $msj)) # convert in base 10 and take the modulus wrt msj: this way we will have msj distinct job names, which, thanks to the singleton directive, means there will be at most msj jobs running at the same time
                $sbatch_script $dynamics_directives -o $it_folder/e$ens.slurm.out -e $it_folder/e$ens.slurm.err --job-name=rea_d$jobID $dynamics_script $T $it_folder/e$ens $1 &
        done
        wait
        
        if $handle_modules ; then
            load_modules $python_modules # restore modules for python
        fi

    else
        # propagate ensemble members in batches (if msj==nens there will be only one batch)
        local last_e=0
        local batch=1
        local keep_going=true
        while $keep_going ; do
            if [[ $(($nens - $msj)) -gt $last_e ]] ; then
                end_e=$(($last_e + $msj))
            else
                end_e=$nens
                keep_going=false
            fi

            python log2telegram.py \""Launching batch $batch"\" 20 $TARGS
            for ens in $(seq -f "%0${#nens}g" $(($last_e + 1)) $end_e ) ; do
                $dynamics_script $T $it_folder/e$ens $1 >$it_folder/e$ens.out 2>$it_folder/e$ens.err &
            done
            wait
            batch=$(($batch + 1))
            last_e=$end_e
        done
    fi
    echo "Dynamics completed" >> $dyn_log
    date >> $dyn_log
}

detect_errors () { # takes as input the folder that will contain *.err files
    errors=false
    local fol=$1 # folder in which to look for error files
    local nl=''
    local f=''
    for f in $fol/*.err ; do
        nl=$(wc -m <$f)
        if [[ $nl -gt 0 ]] ; then # error file contains something
            if ! $errors ; then
                python log2telegram.py \""Detected errors in $f"\" 40 $TARGS
                errors=true
            else
                echo "Errors also in $f"
            fi
        else
            rm $f
        fi
    done
}

log_failure () {
    python log2telegram.py \""$HOSTNAME:\\n\\nRUN FAILED"\" 50 $TARGS
}

check () { # takes as input the folder in which to check that everything is fine
    detect_errors $1
    if $errors ; then
        log_failure
        return 1
    fi
    return 0
}

# ==============================================================================================
# ==============================================================================================


## Check if no arguments were provided and thus print usage
if [[ $# == 0 ]] ; then
    usage
    return 0
    exit 0
fi


###################################
# Set parameters of the algorithm #
###################################


##### hardcoded default values for parameters #####

# parameters of the algorithm
NITER=15 # number of iterations of the algorithm
T=50 # timestep of the algorithm
nens=20 # number of ensemble member
k=2 # selection strenght parameter

# generic parameters
proceed=false # whether to start the run withoud asking for confirmation
initial_ensemble_folder='' # if provided contains the properly named already propagated ensemble members in their first iteration
init_file='' # if provided single init file to initialize all ensemble members at the first iteration
init_ensemble_script='' # if provided script for generating an ensemble from the single init file
p="0" # prefix for the run name
name='' # name of the run
errors=false

# model specific parameters
model=''
model_dir=''
root_folder=''
dynamics_script=''
dynamics_modules=''
cloning_script=''
make_traj_script=''
msj=''

# cluster generic parameters
cluster=false
cluster_dir=''
sbatch_script="sbatch --wait --dependency=singleton" # script for launching the jobs

# cluster specific parameters
srun_mpi=''
partition=''
account=''
directives=''
dynamics_directives=''
handle_modules=true
python_modules=''

# telegram logging parameters
TBT='~/REAVbot.txt' # telegram bot token
CHAT_ID='~/telegram_chat_ID.txt' # telegram chat ID
TLL=30 # telegram logging level


##### Get arguments from the command line #####
parse_command_line "$@"


## now we got information about the cluster and the model, so we can set the proper model- and cluster- specific defaults

# set default values according to the cluster
if $cluster ; then
    cluster_dir="../clusters/$cluster_name"
    if [[ -d $cluster_dir ]] ; then
        . "$cluster_dir/defaults.sh"
    else
        echo "Unrecogniezed cluster option $cluster_name"
        return 1
        exit 1
    fi
    # set default value for python modules
    python_modules="$cluster_dir/modules/python.sh"
fi

# set default values according to the model
if [[ -z ${model} ]] ; then
    echo "You must provide a model name"
    return 1
    exit 1
fi
model_dir="../$model"
if [[ -d $model_dir ]] ; then
    . "$model_dir/defaults.sh"
    root_folder="$model_dir/__test__"
    if $cluster && $handle_modules ; then
        dynamics_modules="$cluster_dir/modules/$model.sh"
    fi
else
    echo "No such directory $model_dir"
    return 1
    exit 1
fi

## parse the command line again to override the defaults
parse_command_line "$@"


### finalize the arguments of the algorithm ###

# check that the module-loading scripts actually exist
if $cluster && $handle_modules ; then
    for file in "$python_modules" "$dynamics_modules" ; do
        if [[ ! -z ${file} ]] ; then
            if [[ ! -f ${file} ]] ; then
                echo "File not found: $1"
                return 1
                exit 1
            fi
        fi
    done
fi

# set the proper number of maximum simultaneous jobs
if [[ $msj == 0 ]] ; then
    msj=$nens
fi

# prepare the sbatch launching command and set mpi envirnoment variable
if $cluster ; then
    if [[ ! -z ${partition} ]] ; then
        sbatch_script="$sbatch_script --partition=$partition"
    fi

    if [[ ! -z ${account} ]] ; then
        sbatch_script="$sbatch_script --account=$account"
    fi

    # add the extra directives
    if [[ ! -z ${directives} ]] ; then
        sbatch_script="$sbatch_script $directives"
    fi

    # export MPI env var
    if [[ -z ${srun_mpi} ]] ; then
        echo "srun_mpi must be set!"
        return 1
        exit 1
    fi
    export SRUN_MPI_ENABLED=$srun_mpi
fi

# set the proper run folder and iteration number
i0=0
if [[ -z ${initial_ensemble_folder} ]] ; then
    # set folder name
    if [[ -z ${name} ]] ; then
        folder="$root_folder/$p--k__$k--nens__$nens--T__$T"
    else
        folder="$root_folder/$name"
    fi

    # check if the run already exists
    if [[ -d ${folder} ]] ; then
        echo "$folder exists! Please choose a new name. If you want to continue a run, please use the -E option"
        return 1
        exit 1
    fi
    
    # check if the provided init file exists
    if [[ ! -z ${init_file} ]] ; then
        if [[ ! -f ${init_file} ]] ; then
            echo "Init file not found: $init_file"
            return 1
            exit 1
        fi
    fi
else
    init_file=''
    folder="${initial_ensemble_folder%/i*}" # remove the iteration folder
    i0="${initial_ensemble_folder##*i}" # this is the name of the iteration folder without the initial 'i'
    i0="${i0%/}" # remove the ending '/'
    i0=$((10#$i0 + 0)) # convert to base 10, properly getting rid of the leading zeros
fi

TARGS="$CHAT_ID $TBT $TLL" # telegram arguments


if ! $proceed ; then
    ## echo a summary of all the arguments
    echo
    echo
    summary

    # ask for confirmation
    read -p "Proceed? (Y/n) " -n 1 -r
    echo # go to new line
    if [[ $REPLY =~ ^[Y]$ ]] ; then
        proceed=true
    fi
fi

if ! $proceed ; then
    echo
    echo "------Aborting------"
    echo
    return 0
    exit 0 # make sure the script exits if return did not work because the script was not sourced
fi


# ==============================================================================================
# ==============================================================================================


#################################
# Start of the actual algorithm #
#################################

echo
echo "------Starting------"
echo

mkdir -p $folder # create the directory for the run folder if it doesn't exist

# log all parameters to a file
arg_file="$folder/parameters.txt"
summary >> $arg_file

# load modules for python
if $cluster && $handle_modules ; then
    load_modules $python_modules
fi

python log2telegram.py \""$HOSTNAME:\\nStarting $NITER iterations in folder $folder"\" 45 $TARGS

### start of the algorithm ###

for n in $(seq 0 $NITER) ; do
    _n=$(printf "%04d" $(($n + $i0)) )
    python log2telegram.py \""------------Iteration $_n-------------"\" 31 $TARGS
    it_folder="$folder/i$_n"
    dyn_log="$it_folder/dynamics.log"
    mkdir -p $it_folder # create the iteration folder

    if [[ $n == 0 ]] ; then # initialization: there might already be an ensemble, we might be continuing another run
        if [[ ! -f "$it_folder/info.json" ]] ; then
            python log2telegram.py \""---Initializing ensemble---"\" 31 $TARGS
            python setup_info.py $it_folder $nens # setup info file for this iteration if it is not there already
        else
            python log2telegram.py \""---Continuing run---"\" 31 $TARGS
        fi

        if [[ ! -f "$it_folder/dynamics.log" ]] ; then # if the dynamics.log file does not exist, we propagate the ensemble in the first iteration
            python log2telegram.py \""---Propagating---"\" 25 $TARGS

            if [[ ! -z ${init_file} ]] ; then
                python log2telegram.py \""---Detected single common ancestor---"\" 25 $TARGS
                if [[ ! -z ${init_ensemble_script} ]] ; then
                    python log2telegram.py \""---Creating ensemble by perturbing initial conditions---"\" 25 $TARGS
                    python $init_ensemble_script $init_file $it_folder $nens
                    init_file=''
                else
                    python log2telegram.py \""---All ensemble members will have exactly the same initial conditions---"\" 25 $TARGS
                fi
            fi

            # run the dynamics with an init file (if provided)
            propagate $init_file
            
            # check that everything went smoothly
            check $it_folder
            if [[ $? -gt 0 ]] ; then # stop the script if check detects errors
                return 1
                exit 1
            fi

        else
            echo
            python log2telegram.py \""Ensemble has already been propagated for this iteration"\" 25 $TARGS
            echo
        fi
    
    else # normal iteration : we propagate each ensemble member from their restart file
        prev_it=$(printf "%04d" $(($n + $i0 - 1)) )
        prev_it_folder="$folder/i$prev_it"

        # compute the score for each ensemble member
        python log2telegram.py \""---Computing scores---"\" 25 $TARGS
        if $cluster ; then
            $sbatch_script -o $prev_it_folder/cs.slurm.out -e $prev_it_folder/cs.slurm.err --job-name=rea_cs scompute_scores.sh $k $prev_it_folder $make_traj_script
        else
            python compute_scores.py $k $prev_it_folder $make_traj_script >$prev_it_folder/cs.out 2>$prev_it_folder/cs.err
        fi

        # check that everything went smoothly
        check $prev_it_folder
        if [[ $? -gt 0 ]] ; then # stop the script if check detects errors
            return 1
            exit 1
        fi

        # selection step, i.e. resampling
        python log2telegram.py \""---Resampling---"\" 25 $TARGS
        if $cluster ; then
            $sbatch_script -o $it_folder/resample.slurm.out -e $it_folder/resample.slurm.err --job-name=rea_r sresample.sh $it_folder $prev_it_folder $cloning_script
        else
            python resample.py $it_folder $prev_it_folder $cloning_script >$it_folder/resample.out 2>$it_folder/resample.err
        fi
        # perturbation of initial conditions is done in the cloning script

        # check that everything went smoothly
        check $it_folder
        if [[ $? -gt 0 ]] ; then # stop the script if check detects errors
            return 1
            exit 1
        fi

        # TODO: this is probably superflous now
        # check that the all init files have been created
        for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
            if  ! compgen -G "$it_folder/e$ens-init*" > /dev/null; then
                echo "Missing init file!!!"
                log_failure
                return 1
                exit 1
            fi
        done

        # propagate the ensmble forward
        if [[ $n != $NITER ]] ; then # do not propagate the last isteration
            python log2telegram.py \""---Propagating---"\" 25 $TARGS

            propagate

            # check that everything went smoothly
            check $it_folder
            if [[ $? -gt 0 ]] ; then # stop the script if check detects errors
                return 1
                exit 1
            fi
        fi
    fi
done

python log2telegram.py \""------------Reconstructing-------------"\" 41 $TARGS
python reconstruct.py "$it_folder"

python log2telegram.py \""$HOSTNAME:\\n\\nRUN COMPLETED"\" 45 $TARGS
echo
echo
