#!/bin/bash

POSITIONAL_ARGS=()

NITER=15
T=10
nens=20
k=2

# while [[ $# -gt 0 ]]; do
#     echo $1
#     POSITIONAL_ARGS+=("$1")
#     shift
# done

# set -- "${POSITIONAL_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--iterations)
            NITER="$2"
            shift # past argument
            shift # past value
            ;;
        -t|--timestep)
            T="$2"
            shift # past argument
            shift # past value
            ;;
        -e|--ensemble-size)
            nens="$2"
            shift # past argument
            shift # past value
            ;;
        -k|--k)
            k="$2"
            shift # past argument
            shift # past value
            ;;
        -*|--*)
            echo "Unknown option $1"
            return 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters so $1 refers to the first positional argument and so on

echo "NITER = $NITER"
echo "T     = $T"
echo "nens  = $nens"
echo "k     = $k"

echo "Positional arguments received: "
for p in "${POSITIONAL_ARGS[@]}" ; do
    echo $p
done

echo $1 $2 $3