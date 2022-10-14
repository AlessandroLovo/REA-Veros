#!/bin/bash

########## Get arguments from command line ##########

## default values for parameters
NITER=15 # number of iterations of the algorithm
T=50 # timestep of the algorithm
nens=20 # number of ensemble member
k=2 # selection strenght parameter
p="0" # prefix

initial_ensemble_folder='' # if provided contains the properly named already propagated ensemble members in their first iteration
init_file='' # if provided single init file to initialize all ensemble members at the first iteration

# useful default arguments
mode='veros'
if [[ "$mode" == "veros" ]] ; then
    root_folder='../veros/__test__' # TODO: update it
    dynamics_modules='../veros/veros_modules.sh' # script that loads the modules for the dynamics
    cloning_script='../veros/perturb_ic.py' # script that clones a trajectory, eventually perturbing initial conditions
    dynamics_script='../veros/veros_batch_restart.sh'
    make_traj_script='../veros/make_traj.py'
    T=100
    msj=5 # max simultaneous jobs
else
    root_folder='../demo/__test__'
    dynamics_modules='../demo/dynamics_modules.sh' # script that loads the modules for the dynamics
    cloning_script='../demo/clone.sh' # script that clones a trajectory, eventually perturbing initial conditions
    dynamics_script='python ../demo/ou.py'
    make_traj_script='None'
    msj=0 # max simultaneous jobs
fi

cluster=false
partition="aegir"
account="ocean"
python_modules='python_modules.sh' # script that loads the modules for python
sbatch_script="sbatch --wait --dependency=singleton"

## telegram logging
TBT='~/REAVbot.txt' # telegram bot token
CHAT_ID='~/telegram_chat_ID.txt' # telegram chat ID
TLL=30 # telegram logging level


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
        -k|--k)
            k="$2"
            shift # past argument
            shift # past value
            ;;
        --cloning-script)
            cloning_script="$2"
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
        --make-traj-script)
            make_traj_script="$2"
            shift
            shift
            ;;
        -E|--initial-ensemble)
            initial_ensemble_folder="$2"
            shift
            shift
            ;;
        -I|--init-file)
            init_file="$2"
            shift
            shift
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

i0=0
echo i0=$i0

if [[ -z ${initial_ensemble_folder} ]] ; then
    folder="$root_folder/$p--k__$k--nens__$nens--T__$T"
else
    init_file=''
    folder="${initial_ensemble_folder%/i*}" # remove the iteration folder
    i0="${initial_ensemble_folder##*i}" # this is the name of the iteration folder without the initial 'i'
    i0="${i0%/}" # remove the ending '/'
    i0=$((10#$i0 + 0)) # evaluate the string so now it is a number
fi
echo i0=$i0

TARGS="$CHAT_ID $TBT $TLL" # telegram arguments

mkdir -p $folder

# log all parameters to a file
arg_file="$folder/parameters.txt"
echo "# parameters of the algorithm " >> $arg_file
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
    _n=$(printf "%04d" $(($n + $i0)) )
    python log2telegram.py \""------------Iteration $_n-------------"\" 31 $TARGS
    it_folder="$folder/i$_n"
    dyn_log="$it_folder/dynamics.log"
    mkdir -p $it_folder # create the iteration folder

    if [[ $n == 0 ]] ; then # initialization: there might already be an ensemble, we might be continuing another run
        if [[ ! -f "$it_folder/info.json" ]] ; then
            python setup_info.py $it_folder $nens # setup info file for this iteration if it is not there already
        fi

        if [[ ! -f "$it_folder/dynamics.log" ]] ; then # if the dynamics.log file does not exist, we propagate the ensemble in the first iteration
            python log2telegram.py \""---Initializing ensemble---"\" 25 $TARGS
            date >> $dyn_log
            echo "Starting dynamics" >> $dyn_log
            if $cluster ; then
                # load modules for running the dynamics
                . $dynamics_modules
                module list

                for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                        jobID=$((10#$ens % $msj))
                        $sbatch_script -o $it_folder/e$ens.slurm.out -e $it_folder/e$ens.slurm.err --job-name=rea_d$jobID $dynamics_script $T $it_folder/e$ens $init_file &
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
                        $dynamics_script $T $it_folder/e$ens $init_file &
                    done
                    wait
                    batch=$(($batch + 1))
                    last_e=$end_e
                done
            fi
            echo "Dynamics completed" >> $dyn_log
            date >> $dyn_log
        else
            echo
            python log2telegram.py \""Ensemble has already been propagated for this iteration"\" 25 $TARGS
            echo
        fi
    
    else # normal iteration : we propagate each ensemble member from their restart file
        prev_it=$(printf "%04d" $(($n + $i0 - 1)) )
        prev_it_folder="$folder/i$prev_it"

        python log2telegram.py \""---Computing scores---"\" 25 $TARGS
        if $cluster ; then
            $sbatch_script -o $prev_it_folder/cs.slurm.out -e $prev_it_folder/cs.slurm.err --job-name=rea_cs scompute_scores.sh $k $prev_it_folder $make_traj_script
        else
            python compute_scores.py $k $prev_it_folder $make_traj_script #$TARGS
        fi

        python log2telegram.py \""---Resampling---"\" 25 $TARGS
        if $cluster ; then
            $sbatch_script -o $it_folder/resample.slurm.out -e $it_folder/resample.slurm.err --job-name=rea_r sresample.sh $it_folder $prev_it_folder $cloning_script
        else
            python resample.py $it_folder $prev_it_folder $cloning_script #$TARGS
        fi
        # perturbation of initial conditions is done in the cloning script

        # check that the init files has been created
        for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
            if  ! compgen -G "$it_folder/e$ens-init*" > /dev/null; then
                echo "Missing init file!!!"
                python log2telegram.py \""$HOSTNAME:\\n\\nRUN FAILED"\" 50 $TARGS
                return 1
            fi
        done


        if [[ $n != $NITER ]] ; then
            python log2telegram.py \""---Propagating---"\" 25 $TARGS

            date >> $dyn_log
            echo "Starting dynamics" >> $dyn_log
            if $cluster ; then
                # load modules for running the dynamics
                . $dynamics_modules
                module list

                for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                        jobID=$((10#$ens % $msj))
                        $sbatch_script -o $it_folder/e$ens.slurm.out -e $it_folder/e$ens.slurm.err --job-name=rea_d$jobID $dynamics_script $T $it_folder/e$ens &
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
                        $dynamics_script $T $it_folder/e$ens &
                    done
                    wait
                    batch=$(($batch + 1))
                    last_e=$end_e
                done
            fi
            echo "Dynamics completed" >> $dyn_log
            date >> $dyn_log
        fi
    fi
done

python log2telegram.py \""------------Reconstructing-------------"\" 41 $TARGS
python reconstruct.py "$it_folder"

python log2telegram.py \""$HOSTNAME:\\n\\nRUN COMPLETED"\" 45 $TARGS
echo
echo
