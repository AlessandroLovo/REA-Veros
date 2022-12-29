# Veros runs

## rr
Initial ensemble (50 members) provided by Johannes, propagated on the first iteration (100 years).

**DO NOT perform runs in this directory!!!!!**

## r1
Run using the `rr` ensemble. Resampling time $t=50$ years, selection strength $k=8$.

## r2
Run using the `rr` ensemble. Resampling time $t=50$ years, selection strength $k=20$.

## r2-relax
Run starting from `r2/i0010` to see the relaxation. Resampling time $t=50$ years, selection strength $k=0$.

## r2-relax-tc
Same as `r2-relax`, but with telescopic canceling of the scores enambled. There is a mess in the selection at the discontinuity in $k$: do not use

## r3
Run using the `rr` ensemble. Resampling time $t=20$ years, selection strength $k=16$.

## r01--k__16--nens__50--T__5
Run initialized with `rr/i0000/e01.0000.restart.h5`, with 50 ensemble members. Resampling time $t=5$ years (the minimum possible), selection strength $k=16$.


# Tests
Other folders starting with `t` contain some methodological tests. Nothing scientifically relevant