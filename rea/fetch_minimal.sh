#!/bin/bash

usage () {
    echo "This script fetches a (minimal) run from a cluster"
    echo
    echo "Usage:"
    echo "    . fetch_minimal.sh [user@]host:<path/to/run_folder> [<destination>]" 
    echo "You can also use"
    echo "    . fetch_minimal.sh [user@]host [<destination>]"
    echo "To fetch the minimal version of the last run performed on the server"
}

## Check that the script is being launched from the correct directory
if [[ "$(pwd)" != */rea ]] ; then
    echo "You need to source this script from the directory that contains it!!"
    return 1
    exit 1
fi

## Check if no arguments were provided and thus print usage
if [[ $# == 0 ]] ; then
    usage
    return 0
    exit 0
fi

last_run_file_name=".reav-last_run.txt"
last_run_file="$HOME/$last_run_file_name"

folder="$1"

if [[ "$folder" != *:* ]] ; then # check if folder contains ':' so we distinguish a host from a host:path
    # here folder is the host name
    rm -f $last_run_file
    scp $folder:$last_run_file_name $HOME

    if [[ ! -f $last_run_file ]] ; then
        echo "Couldn't find last run file on host $folder"
        return 1
        exit 1
    fi

    folder="$folder:$(head -n 1 $last_run_file)"
    folder="${folder%/}_minimal"
fi

folder="${folder%/}"
run_name="${folder##*/}"

if [[ $run_name != *minimal ]] ; then
    echo
    echo "WARNING: You are trying to scp a non minimal run: this could take very long"
    echo
    proceed=false
    if ! $proceed ; then
        # ask for confirmation
        read -p "Proceed? (Y/n) " -n 1 -r
        echo # go to new line
        if [[ $REPLY =~ ^[Y]$ ]] ; then
            proceed=true
        fi
    fi

    if ! $proceed ; then
        echo
        echo "------Aborting------"
        echo
        return 0
        exit 0 # make sure the script exits if return did not work because the script was not sourced
    fi
fi

if [[ -z $2 ]] ; then
    destination="..${folder##*REA-Veros}"
else
    destination="$2"
fi
destination="${destination%/}"
ending="${destination##*/}"
if [[ "$ending" != "$run_name" ]] ; then
    destination="$destination/$run_name"
fi

echo "Fetching $folder into $destination"
proceed=false
if ! $proceed ; then
    # ask for confirmation
    read -p "Proceed? (Y/n) " -n 1 -r
    echo # go to new line
    if [[ $REPLY =~ ^[Y]$ ]] ; then
        proceed=true
    fi
fi

if ! $proceed ; then
    echo
    echo "------Aborting------"
    echo
    return 0
    exit 0 # make sure the script exits if return did not work because the script was not sourced
fi


if [[ ! -d $destination ]] ; then # destination directory doesn't exist: we scp the entire directory
    # try to scp the tar archive if present
    scp $folder.tar.gz $destination.tar.gz

    if [[ $? == 0 ]] ; then
        echo "Successfully fetched archive of $folder: extracting it"

        # split destination in filename and path
        root_folder="${destination%/*}"
        filename="${destination##*/}"

        # move to directory, extract and move back
        cd $root_folder
        tar xzf $filename.tar.gz
        cd -
    else
        echo "Could not fetch archive of $folder, trying to scp the folder itself"
        scp -r $folder "${destination%/*}"
    fi
    return 0
    exit 0 # if return fails, we exit. If return succeeds this line won't be executed
fi

mkdir -p $destination

scp $folder/parameters.txt $destination/

# check that we actually copied the file
if [[ ! -f "$destination/parameters.txt" ]] ; then
    echo "Could not fetch run $folder"
    # remove the destination directory only if it is empty
    rmdir $destination 2> /dev/null
    return 1
    exit 1
fi

scp $folder/reconstructed.json $destination/

for n in {0..9999} ; do
    echo $n
    _n=$(printf "%04d" $n)
    it="i$_n"

    ntraj=$(ls $destination/$it/*traj.npy 2> /dev/null | wc -l)
    if [[ $ntraj == 0 ]] ; then
        scp -r $folder/$it $destination
        if [[ $? != 0 ]] ; then
            echo "Reached last iteration"
            break
        fi
    else
        echo "Skipping"
    fi
done