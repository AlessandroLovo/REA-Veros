#!/bin/bash

d=$(dirname ${BASH_SOURCE[0]})

echo indirect_call: ${BASH_SOURCE}
echo $d

. $d/../locate_script/locate_script.sh baluga