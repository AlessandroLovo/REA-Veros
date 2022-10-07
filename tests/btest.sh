#!/bin/bash

nens=13
msj=3

last_e=0
# keep_going=true
# while $keep_going ; do
#     echo launching batch
#     if [[ $(($nens - $maxj)) -gt $last_e ]] ; then
#         end_e=$(($last_e + $maxj))
#     else
#         end_e=$nens
#         keep_going=false
#     fi
#     for ens in $(seq -f "%0${#nens}g" $(($last_e + 1)) $end_e ) ; do
#         echo $ens
#     done
#     last_e=$end_e
# done

# if [[ $last_e ]] ; then
# echo ha!
# fi

for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
    jobID="$((10#$ens % $msj))"
    # $sbatch_script --job-name=rea$jobID $dynamics_script $T $it_folder/e$ens $init_file &
    echo rea$jobID
done

# echo $@