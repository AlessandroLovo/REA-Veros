#!/bin/bash

fol="$1"


detect_errors () {
    local errors=false
    for f in $fol/*.err ; do
        nl=$(wc -m <$f)
        if [[ $nl -gt 0 ]] ; then
            echo "Detected errors in $f"
            errors=true
        else
            echo "Removing $f"
        fi
    done

    if $errors ; then
        return 1
    else
        return 0
    fi
}

detect_errors
if [[ $? -gt 0 ]] ; then
    echo "ERRORS HAVE BEEN DETECTED"
    return 1
    exit 1
fi

echo "Everything is fine"