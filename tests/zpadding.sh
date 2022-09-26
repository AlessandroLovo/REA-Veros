#!/bin/bash

nens=$1

for ens in $(seq -f "%0${#nens}g" 1 $nens) ; do
    echo $ens
done