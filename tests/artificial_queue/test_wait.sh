#!/bin/bash

./dyn.sh 24 baluga &
./dyn.sh 13 forense &
wait

echo "Done"