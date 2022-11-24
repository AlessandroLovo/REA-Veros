#!/bin/bash

a=true
b=''

if $a && $b ; then
    echo baluga
fi

u=12

if [[ ! -z $u ]] ; then
    echo first argument is $u
fi

for i in $a $b ; do
    echo $i
done

echo "You have 5 seconds to stop the run if you disagree with the seetings"
sleep 5

proceed=false
read -p "Proceed? (Y/n)" -n 1 -r
# read -n 1 REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Y]$ ]] ; then
    proceed=true
fi

if ! $proceed ; then
    return 0
    exit 0
fi

echo "DONEEEEEE"