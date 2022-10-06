#!/bin/bash

folder='__test__/iti/i0005/'

root_folder="${folder%/i*}"
echo $root_folder
num="${folder##*i}"
echo $num
num="${num%/*}"
echo $num
num=$(($num + 0))
echo $num

