#!/bin/bash

a=true
b=true

if $a && $b ; then
    echo baluga
fi

u=12

if [[ ! -z $u ]] ; then
    echo first argument is $u
fi