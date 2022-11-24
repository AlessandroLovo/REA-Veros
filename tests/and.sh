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