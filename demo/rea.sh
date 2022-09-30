#!/bin/bash

########## Get arguments from command line ##########

## default values for parameters
NITER=15 # number of iterations of the algorithm
T=50 # timestep of the algorithm
nens=20 # number of ensemble member
k=2 # selection strenght parameter
p="0" # prefix

root_folder='./__test__'

max_simultaneous_jobs=0
cluster=false
partition="aegir"

_sbatch_script="sbatch --wait"

dynamics_script='python ou.py'

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
        --cluster)
            cluster=true
            shift
            ;;
        -P|--partition)
            partition="$2"
            shift # past argument
            shift # past value
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

if [[ ! -z ${partition} ]] ; then
    _sbatch_script="$_sbatch_script --partition=$partition"
fi

folder="$root_folder/$p--k__$k--nens__$nens--T__$T"

TARGS="$CHAT_ID $TBT $TLL"

python log2telegram.py \""$HOSTNAME:\\nStarting $NITER iterations in folder $folder"\" 45 $TARGS

for n in $(seq 0 $NITER) ; do
    _n=$(printf "%04d" $n)
    python log2telegram.py \""------------Iteration $_n-------------"\" 31 $TARGS
    it_folder="$folder/i$_n"
    mkdir -p $it_folder # create the iteration folder

    if [[ $n == 0 ]] ; then # initialization
        echo "---Initializing ensemble---"
        python setup_info.py $it_folder $nens # setup info file for this iteration

        if $cluster ; then
            sbatch_script=$_sbatch_script
            if [[ $max_simultaneous_jobs == 0 ]] ; then
                msj=$nens
            else
                sbatch_script="$sbatch_script --dependency=singleton"
                msj=$max_simultaneous_jobs
            fi

            for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                    jobID=$(($ens % $msj))
                    $sbatch_script --jobName=$jobID $dynamics_script $T $it_folder/e$ens- &
            done
            wait

        else
            if [[ $max_simultaneous_jobs == 0 ]] ; then
                # propagate all ensemble members at once
                for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                    $dynamics_script $T $it_folder/e$ens- &
                done
                wait
            else
                # propagate ensemble members in batches
                last_e=0
                batch=1
                keep_going=true
                while $keep_going ; do
                    if [[ $(($nens - $max_simultaneous_jobs)) -gt $last_e ]] ; then
                        end_e=$(($last_e + $max_simultaneous_jobs))
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
        fi
    else
        prev_it=$(printf "%04d" $(( n - 1 )) )
        prev_it_folder="$folder/i$prev_it"

        echo "---Computing scores---"
        python compute_scores.py $k $prev_it_folder #$TARGS

        # set up info file for this iteration
        # this is not necessary as it would be done anyways by the resampling script
        python setup_info.py $it_folder $nens

        echo "---Selecting---"
        python resample.py $it_folder $prev_it_folder #$TARGS

        # TODO: add perturbation of initial conditions

        if [[ $n != $NITER ]] ; then
            echo "---Propagating---"

            if $cluster ; then
                sbatch_script=$_sbatch_script
                if [[ $max_simultaneous_jobs == 0 ]] ; then
                    msj=$nens
                else
                    sbatch_script="$sbatch_script --dependency=singleton"
                    msj=$max_simultaneous_jobs
                fi

                for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                        jobID=$(($ens % $msj))
                        $sbatch_script --jobName=$jobID $dynamics_script $T $it_folder/e$ens- $it_folder/e$ens-init.npy &
                done
                wait

            else
                if [[ $max_simultaneous_jobs == 0 ]] ; then
                    # propagate all ensemble members at once
                    for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                        $dynamics_script $T $it_folder/e$ens- $it_folder/e$ens-init.npy &
                    done
                    wait
                else
                    # propagate ensemble members in batches
                    last_e=0
                    batch=1
                    keep_going=true
                    while $keep_going ; do
                        if [[ $(($nens - $max_simultaneous_jobs)) -gt $last_e ]] ; then
                            end_e=$(($last_e + $max_simultaneous_jobs))
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
            for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
                $dynamics_script $T $it_folder/e$ens- $it_folder/e$ens-init.npy &
            done
            wait
        fi
    fi
done

python log2telegram.py \""------------Reconstructing-------------"\" 41 $TARGS
python reconstruct.py "$it_folder"

python log2telegram.py \""$HOSTNAME:\\n\\nTASK COMPLETED"\" 45 $TARGS
echo
echo