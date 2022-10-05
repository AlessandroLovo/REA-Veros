#!/bin/bash

########## Get arguments from command line ##########

## default values for parameters
NITER=15 # number of iterations of the algorithm
T=50 # timestep of the algorithm
nens=20 # number of ensemble member
k=2 # selection strenght parameter
p="0" # prefix

# useful default arguments
mode='demo'
if [[ "$mode" == "veros" ]] ; then
    root_folder='../veros/__test__' # TODO: update it
    dynamics_modules='../veros/veros_modules.sh' # script that loads the modules for the dynamics
    cloning_script='../veros/perturb_ic.py' # script that clones a trajectory, eventually perturbing initial conditions
    dynamics_script='../veros/veros_batch_restart.sh'
    make_traj_script='../veros/make_traj.py'
    T=100
else
    root_folder='../demo/__test__'
    dynamics_modules='../demo/dynamics_modules.sh' # script that loads the modules for the dynamics
    cloning_script='../demo/clone.sh' # script that clones a trajectory, eventually perturbing initial conditions
    dynamics_script='python ../demo/ou.py'
    make_traj_script='None'
fi

msj=0 # max simultaneous jobs
cluster=false
partition="aegir"
account="ocean"
python_modules='python_modules.sh' # script that loads the modules for python
sbatch_script="sbatch --wait --dependency=singleton"

## telegram logging
TBT='~/REAVbot.txt' # telegram bot token
CHAT_ID='~/telegram_chat_ID.txt' # telegram chat ID
TLL=40 # telegram logging level


while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--iterations)
            NITER="$2"
            shift # past argument
            shift # past value
            ;;
        -d|--dynamics)
            dynamics_script="$2"
            shift
            shift
            ;;
        --cloning-script)
            cloning_script="$2"
            shift
            shift
            ;;
        --make-traj-script)
            make_traj_script="$2"
            shift
            shift
            ;;
        -t|--timestep)
            T="$2"
            shift # past argument
            shift # past value
            ;;
        -e|--ensemble-size)
            nens="$2"
            shift # past argument
            shift # past value
            ;;
        -k|--k)
            k="$2"
            shift # past argument
            shift # past value
            ;;
        -p|--prefix)
            p="$2"
            shift # past argument
            shift # past value
            ;;
        -r|--root|--root-folder)
            root_folder="$2"
            shift # past argument
            shift # past value
            ;;
        -j|--jobs)
            msj="$2"
            shift # past argument
            shift # past value
            ;;
        --cluster)
            cluster=true
            shift
            ;;
        -P|--partition)
            partition="$2"
            shift # past argument
            shift # past value
            ;;
        -A|--account)
            account="$2"
            shift # past argument
            shift # past value
            ;;
        --python-modules)
            python_modules="$2"
            shift
            shift
            ;;
        --dynamics-modules)
            dynamics_modules="$2"
            shift
            shift
            ;;
        -b|--bot-token)
            TBT="$2"
            shift # past argument
            shift # past value
            ;;
        -c|--chat-id)
            CHAT_ID="$2"
            shift # past argument
            shift # past value
            ;;
        -l|--log-level)
            TLL="$2"
            shift # past argument
            shift # past value
            ;;
        -*|--*)
            echo "Unknown option $1"
            return 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters so $1 refers to the first positional argument and so on

########## Actual script ##########

### preliminary operations ###

if [[ $msj == 0 ]] ; then
    msj=$nens
fi

if [[ ! -z ${partition} ]] ; then
    sbatch_script="$sbatch_script --partition=$partition"
fi

if [[ ! -z ${account} ]] ; then
    sbatch_script="$sbatch_script --account=$account"
fi

folder="$root_folder/$p--k__$k--nens__$nens--T__$T"

TARGS="$CHAT_ID $TBT $TLL" # telegram arguments

# log all parameters to a file
arg_file="$folder/parameters.txt"
echo "# parameters of the algorithm ">> $arg_file
echo "NITER : $NITER # number of iterations" >> $arg_file
echo "T : $T # resampling timestep" >> $arg_file
echo "nens : $nens # number of ensemble members" >> $arg_file
echo "k : $k # selection strenght" >> $arg_file
echo >> $arg_file
echo "# Dynamics ">> $arg_file
echo "dynamics_script : $dynamics_script # script that runs the dynamics" >> $arg_file
echo "cloning_script : $cloning_script # script that clones trajectories, possibly perturbing initial conditions">> $arg_file
echo "make_traj_script : $make_traj_script # script to postprocess the output of the dynamics and compute the trajectory of the observable needed for the score" >> $arg_file
echo >> $arg_file
echo "# Execution parameters that do not affect the result" >> $arg_file
echo "prefix : $p # prefix for this folder name" >> $arg_file
echo "jobs : $msj # maximum number of simultaneous jobs" >> $arg_file
echo >> $arg_file
echo "cluster : $cluster # whether the algorithm is run on a cluster">> $arg_file
if $cluster ; then
    echo "    partition : $partition" >> $arg_file
    echo "    account : $account" >> $arg_file
    echo "    python modules loaded from : $python_modules" >> $arg_file
    echo "    dynamics modules loaded from : $dynamics_modules" >> $arg_file
fi
echo >> $arg_file

# load modules for python
if $cluster ; then
    module purge
    . $python_modules
    module list
fi

python log2telegram.py \""$HOSTNAME:\\nStarting $NITER iterations in folder $folder"\" 45 $TARGS

### start of the algorithm ###

for n in $(seq 0 $NITER) ; do
    _n=$(printf "%04d" $n)
    python log2telegram.py \""------------Iteration $_n-------------"\" 31 $TARGS
    it_folder="$folder/i$_n"
    mkdir -p $it_folder # create the iteration folder

    if [[ $n == 0 ]] ; then # initialization: there is no restart file for each ensemble member
        echo "---Initializing ensemble---"
        python setup_info.py $it_folder $nens # setup info file for this iteration

        if $cluster ; then
            # load modules for running the dynamics
            . $dynamics_modules
            module list

            for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                    jobID=$($ens % $msj)
                    $sbatch_script --job-name=rea$jobID $dynamics_script $T $it_folder/e$ens- &
            done
            wait

            # restore modules for python
            module purge
            . $python_modules

        else
            # propagate ensemble members in batches (if msj==nens there will be only one batch)
            last_e=0
            batch=1
            keep_going=true
            while $keep_going ; do
                if [[ $(($nens - $msj)) -gt $last_e ]] ; then
                    end_e=$(($last_e + $msj))
                else
                    end_e=$nens
                    keep_going=false
                fi

                python log2telegram.py \""Launching batch $batch"\" 20 $TARGS
                for ens in $(seq -f "%0${#nens}g" $(($last_e + 1)) $end_e ) ; do
                    $dynamics_script $T $it_folder/e$ens- &
                done
                wait
                batch=$(($batch + 1))
                last_e=$end_e
            done
        fi
    
    else # normal iteration : we propagate each ensemble member from their restart file
        prev_it=$(printf "%04d" $(( n - 1 )) )
        prev_it_folder="$folder/i$prev_it"

        echo "---Computing scores---"
        if $cluster ; then
            $sbatch_script --job-name=rea_cs scompute_scores.sh $k $prev_it_folder
        else
            python compute_scores.py $k $prev_it_folder $make_traj_script #$TARGS
        fi

        ## set up info file for this iteration
        ## this is not necessary as it would be done anyways by the resampling script
        # python setup_info.py $it_folder $nens

        echo "---Selecting---"
        if $cluster ; then
            $sbatch_script --job-name=rea_r sresample.sh $it_folder $prev_it_folder $cloning_script
        else
            python resample.py $it_folder $prev_it_folder $cloning_script #$TARGS
        fi
        # perturbation of initial conditions is done in the cloning script

        if [[ $n != $NITER ]] ; then
            echo "---Propagating---"

            if $cluster ; then
                # load modules for running the dynamics
                . $dynamics_modules
                module list

                for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                        jobID=$($ens % $msj)
                        $sbatch_script --job-name=rea$jobID $dynamics_script $T $it_folder/e$ens- $it_folder/e$ens-init.npy &
                done
                wait

                # restore modules for python
                module purge
                . $python_modules

            else
                # propagate ensemble members in batches (if msj==nens there will be only one batch)
                last_e=0
                batch=1
                keep_going=true
                while $keep_going ; do
                    if [[ $(($nens - $msj)) -gt $last_e ]] ; then
                        end_e=$(($last_e + $msj))
                    else
                        end_e=$nens
                        keep_going=false
                    fi

                    python log2telegram.py \""Launching batch $batch"\" 20 $TARGS
                    for ens in $(seq -f "%0${#nens}g" $(($last_e + 1)) $end_e ) ; do
                        $dynamics_script $T $it_folder/e$ens- $it_folder/e$ens-init.npy &
                    done
                    wait
                    batch=$(($batch + 1))
                    last_e=$end_e
                done
            fi
        fi
    fi
done

python log2telegram.py \""------------Reconstructing-------------"\" 41 $TARGS
python reconstruct.py "$it_folder"

python log2telegram.py \""$HOSTNAME:\\n\\nTASK COMPLETED"\" 45 $TARGS
echo
echo