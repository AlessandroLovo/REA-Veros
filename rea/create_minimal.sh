#!/bin/bash

usage () {
    echo "This script creates a minimal version of a run in a folder named <run_folder>_minimal"
    echo "The minimal folder will contain the parameters of the run, the reconstructed dictionary and for every iteration only the trajectorie and info files"
    echo
    echo "Usage:"
    echo "    . create_minimal.sh <path/to/run_folder>"
    echo "You can also use"
    echo "    . create_minimal.sh last"
    echo "To create the minimal version of the last run performed on the local machine"
}

## Check if no arguments were provided and thus print usage
if [[ $# == 0 ]] ; then
    usage
    return 0
    exit 0
fi

last_run_file="$HOME/.reav-last_run.txt"

folder="$1"
folder="${folder%/}"

if [[ "$folder" == "last" ]] ; then
    if [[ ! -f $last_run_file ]] ; then
        echo "Last run file not found: cannot use option 'last'"
        return 1
        exit 1
    fi
    folder=$(head -n 1 $last_run_file)
fi

if [[ ! -d $folder ]] ; then
    echo "Folder $folder not found!"
    return 1
    exit 1
fi

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
        ntraj=$(ls $dest/*traj.npy 2> /dev/null | wc -l)
        if [[ $ntraj == 0 ]] ; then 
            cp $subf/info.json $dest
            cp $subf/*traj.npy $dest
        else
            echo Skipping folder $dest
        fi
    fi
done

# compress into tar archive
tar czf $folder_minimal.tar.gz $folder_minimal