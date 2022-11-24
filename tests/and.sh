#!/bin/bash

a=true
b=true

if $a && $b ; then
    echo baluga
fi

if [[ ! -z $1 ]] ; then
    echo first argument is $1
fi