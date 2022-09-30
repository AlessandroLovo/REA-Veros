#!/bin/bash

# set -e

script="python test.py"


$script $1 &
$script $1 $2 &
$script $1 &
wait -n

echo
echo Finished
