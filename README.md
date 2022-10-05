# REA-Veros

Running the GKTL rare event algorithm on the Versatile Ocean Simulator (Veros)

## folder structure

1. `rea`: code with the rare event algorithm, divided in several scripts and quite versatile
2. `veros`: code for running the veros ocean model, mainly on a cluster
3. `demo`: benchmark of the rare event algorithm on simple 1D dynamics like the Ornstein-Uhlenbeck process or a simple double well potential
4. `tests`: various simple tests of the components of the code, there shouldn't be anything interesting in there
5. `orig`: original version of the code by Johannes Lohmann
6. `general_purpose`: submodule with general purpose functions

## code structure

The main script is `rea/rea.sh` and is the one coordinating everything: it supports different dynamics besides veros and can be run on clusters that use `slurm`

Pseudocode:


```
# Initialize `nens` ensemble members and propagate them for the first timestep `T`
for i in {1..NITER} do
    # compute score of the previous iteration
    # resample initial conditions for the current iteration
    # propagate each ensemble member
done
```