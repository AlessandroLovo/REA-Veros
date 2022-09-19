#!/bin/bash

ITER=0
IC=100
FIL="REA$IC""i$ITER"
echo "$FIL"

START=100
ITER0=0

### initialize with 5 parallel runs
for i in {0..4}
do
  IC=$(( $START + $i ))
  RES=$(( $START + 2*$i )) # why the 2* ?
  echo "Iteration: $IC"
  echo "Restart file: $RES"
  #ITER=$(( $ITER0 + $i ))
  #echo "Iteration: $ITER"
  FIL="REA$IC""i$ITER"

  #if [ $i -gt 0 ]
  #then
  cp s720ur2b.0$RES.restart.h5 s720ur2b.0$RES.restartP.h5
  echo "Perturbing IC"
  module load anaconda 
  python perturb_ic.py $RES
  module purge
  module list
  #fi

  echo "This script is about to run another script."
  sbatch --job-name=R$IC ./veros_batch_restart.sh $IC $FIL $RES
  echo "This script has just run another script."
done

FIL0="REA$START""i$ITER"

while [ 149 -gt $IC ] # what does this do?
do
  while true
  do
    echo "Searching"
    echo "$FIL0.0000.restart.h5"
    if [ -f "$FIL0.0000.restart.h5" ]
    then
      echo "Simulation complete"
      IC=$(( $IC + 1 ))
      RES=$(( $RES + 2 ))
      FIL="REA$IC""i$ITER"
      
      cp s720ur2b.0$RES.restart.h5 s720ur2b.0$RES.restartP.h5
      echo "Perturbing IC"
      module load anaconda 
      python perturb_ic.py $RES
      module purge
      module list

      sbatch --job-name=R$IC ./veros_batch_restart.sh $IC $FIL $RES
      START=$(( $START + 1 ))
      FIL0="REA$START""i$ITER"
      echo "$START"
      echo "$IC"
      break
    else
      echo "sleeping"
      sleep 60
    fi
  done
done
