#!/bin/bash

T=10
it_folder="__test__"

# telegram logging parameters
TBT='~/REAVbot.txt' # telegram bot token
CHAT_ID='~/telegram_chat_ID.txt' # telegram chat ID
TLL=20 # telegram logging level
TARGS="$CHAT_ID $TBT $TLL" # telegram arguments

sbatch_script="sbatch"
dynamics_directives="--time=00:03:00"
dynamics_script="./dyn.sh"

################################################

nens=10
msj=2
epj=3
batch_launch_template="batch_launch_template.sh"
check_every="1m"

propagate () {
    local last_e=0
    local batch=1
    local keep_going=true
    while $keep_going ; do
        if [[ $(($nens - $epj)) -gt $last_e ]] ; then
            end_e=$(($last_e + $epj))
        else
            end_e=$nens
            keep_going=false
        fi

        # create batch launch file
        batch_launch_file="$it_folder/batch_launch-$batch.sh"
        cp $batch_launch_template $batch_launch_file

        python log2telegram.py \""Launching batch $batch"\" 20 $TARGS
        for ens in $(seq -f "%0${#nens}g" $(($last_e + 1)) $end_e ) ; do
            echo "$dynamics_script $T $it_folder/e$ens $1 >$it_folder/e$ens.out 2>$it_folder/e$ens.err &" >> $batch_launch_file
        done
        echo "wait" >> $batch_launch_file
        echo "" >> $batch_launch_file

        # submit job    
        $sbatch_script $dynamics_directives -o $it_folder/b$batch.out -e $it_folder/b$batch.err $batch_launch_file

        # check if we can submit another job by looking at the queue
        sleep $check_every # give time to update the queue
        while [[ $(squeue --me | wc -l) -gt $msj ]] ; do
            sleep $check_every
        done

        batch=$(($batch + 1))
        last_e=$end_e
    done

    # wait for the queue to empty
    while [[ $(squeue --me | wc -l) -gt 1 ]] ; do
        sleep $check_every
    done
}

if [[ ! -d $it_folder ]] ; then
    mkdir $it_folder
fi

propagate

echo "DONE!"