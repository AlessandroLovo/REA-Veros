#!/bin/bash

NITER=2
T=10
folder="./__test__"
nens=5
k=0.2

for n in $(seq 0 $NITER) ; do
    _n=$(printf "%04d" $n)
    echo "------------Iteration $_n-------------"
    it_folder="$folder/i$_n"
    mkdir -p $it_folder

    if [[ $n == 0 ]] ; then
        echo ---Initializing ensemble---
        python setup_info.py $it_folder $nens
        for ens in $(seq -f "%03g" 1 $nens) ; do
            python ou.py $T $it_folder/e$ens-
        done
    else
        prev_it=$(printf "%04d" $(( n - 1 )) )
        prev_it_folder="$folder/i$prev_it"

        echo ---Computing scores---
        python compute_scores.py $k $prev_it_folder

        # set up info file for this iteration
        python setup_info.py $it_folder $nens
        echo ---Selecting---
        python resample.py $it_folder $prev_it_folder

        echo ---Propagating---
        for ens in $(seq -f "%03g" 1 $nens) ; do
            python ou.py $T $it_folder/e$ens- $it_folder/e$ens-init.npy
        done
    fi


done