#!/bin/bash

# scps the minimal version of a run
folder="$1"
folder="${folder%/}"
run_name="${folder##*/}"

if [[ -z $2 ]] ; then
    destination='.'
else
    destination="$2"
fi
destination="${destination%/}"
ending="${destination##*/}"
if [[ "$ending" != "$run_name" ]] ; then
    destination="$destination/$run_name"
fi

if [[ ! -d $destination ]] ; then
    scp -r $folder "${destination%/*}"
    return 0
fi

mkdir -p $destination

scp $folder/parameters.txt $destination/
scp $folder/reconstructed.json $destination/

for n in {0..10} ; do
    echo $n
    _n=$(printf "%04d" $n)
    it="i$_n"

    ntraj=$(ls $destination/$it/*traj.npy 2> /dev/null | wc -l)
    if [[ $ntraj == 0 ]] ; then
        scp -r $folder/$it $destination
        if [[ $? != 0 ]] ; then
            echo "Reched last iteration"
            break
        fi
    else
        echo "Skipping"
    fi
done