# Veros runs

All the following names are found as folders in the `__test__` directory. Since this directory is ignored by git, it contains different runs depending on the cluster.

Each run has a `*_minimal` version that contains only the `*-traj.npy` files and the `info.json` ones. Namely, the minimum information needed to visualize the run. These minimal version do not contain restart files, so they cannot be used to continue runs.

---

## Runs @ HPC
Cluster in Copenhagen

The following runs are performed with `forc_val=8.2e-7`

### rr
Initial ensemble (50 members) provided by Johannes, propagated on the first iteration (100 years).

**DO NOT perform runs in this directory!!!!!**

### r1
Run using the `rr` ensemble. Resampling time $t=50$ years, selection strength $k=8$.

### r2
Run using the `rr` ensemble. Resampling time $t=50$ years, selection strength $k=20$.

### r2-relax
Run starting from `r2/i0010` to see the relaxation. Resampling time $t=50$ years, selection strength $k=0$.

### r2-relax-tc
Same as `r2-relax`, but with telescopic canceling of the scores enabled. There is a mess in the selection at the discontinuity in $k$: do not use

### r3
Run using the `rr` ensemble. Resampling time $t=20$ years, selection strength $k=16$.

### r01--k__16--nens__50--T__5
Run initialized with `rr/i0000/e01.0000.restart.h5`, with 50 ensemble members. Resampling time $t=5$ years (the minimum possible), selection strength $k=16$.

---

## Runs @ PSMN
Cluster in Lyon

The following runs are performed with `forc_val=8.375e-7`

### rf1
Run initialized with `i_forc8375e-7/salt720ur375.0222.restart.5`, with 50 ensemble members. Resampling time $t=20$ years, selection strength $k=16$


# Tests
Other folders starting with `t` contain some methodological tests, and are present in every cluster. Nothing scientifically relevant

---

## Runs @ lorenz
Cluster in Utrecht

### r-0_minimal
Run at k=0

