#!/bin/bash

keyword='committor'
sleep_time=3

while true ; do
    echo 'Checking'
    nprocesses=$(ps ax | grep $keyword | wc -l)
    if [[ $nprocesses -lt 2 ]] ; then
        break
    fi
    sleep $sleep_time
done

echo "Process has terminated: launching"