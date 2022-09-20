#!/bin/bash

########## Get arguments from command line ##########

## default values for parameters
NITER=15 # number of iterations of the algorithm
T=10 # timestep of the algorithm
nens=20 # number of ensemble member
k=2 # selection strenght parameter

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

folder="./__test__/k__$k--nens__$nens--T__$T"

TARGS="$CHAT_ID $TBT $TLL"

python log2telegram.py \""Starting $NITER iterations in folder $folder"\" $TARGS

for n in $(seq 0 $NITER) ; do
    _n=$(printf "%04d" $n)
    echo "------------Iteration $_n-------------"
    it_folder="$folder/i$_n"
    mkdir -p $it_folder # create the iteration folder

    if [[ $n == 0 ]] ; then # initialization
        echo "---Initializing ensemble---"
        python setup_info.py $it_folder $nens # setup info file for this iteration

        # propagate all unsemble members
        for ens in $(seq -f "%03g" 1 $nens) ; do
            python ou.py $T $it_folder/e$ens-
        done
    else
        prev_it=$(printf "%04d" $(( n - 1 )) )
        prev_it_folder="$folder/i$prev_it"

        echo "---Computing scores---"
        python compute_scores.py $k $prev_it_folder #$TARGS

        # set up info file for this iteration
        python setup_info.py $it_folder $nens
        echo "---Selecting---"
        python resample.py $it_folder $prev_it_folder #$TARGS

        # NOTE: maybe the last iteration should not propagate
        echo "---Propagating---"
        for ens in $(seq -f "%03g" 1 $nens) ; do
            python ou.py $T $it_folder/e$ens- $it_folder/e$ens-init.npy
        done
    fi
done

echo "------------Reconstructing-------------"
python reconstruct.py "$it_folder"

python log2telegram.py \""TASK COMPLETED"\" $TARGS
echo
echo