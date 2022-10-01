#!/bin/bash

nens=13
maxj=3

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

if [[ $last_e ]] ; then
echo ha!
fi

echo $@