#!/bin/bash

# creates a minimal version of the run to scp
folder="$1"
folder="${folder%/}"
folder_minimal="${folder}_minimal"

mkdir -p $folder_minimal
cp $folder/parameters.txt $folder_minimal/
cp $folder/reconstructed.json $folder_minimal/

for subf in $folder/i* ; do
    if [[ -d $subf ]] ; then
        ending="${subf##*/}"
        echo $ending
        dest="$folder_minimal/$ending"
        mkdir -p $dest
        ntraj=$(ls $dest/*traj.npy | wc -l)
        if [[ $ntraj == 0 ]] ; then 
            cp $subf/info.json $dest
            cp $subf/*traj.npy $dest
        else
            echo Skipping folder $dest
        fi
    fi
done