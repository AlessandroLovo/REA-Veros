# Setting up the veros model

In this file we show how to properly setup an environment for running veros

The first thing you need to do is clone the proper version of veros from the github [repo](https://github.com/team-ocean/veros).
In this repo we work with version **0.2.3**

```
git clone https://github.com/team-ocean/veros.git -b v0.2.3
```

that will create the folder named `veros`


## Install everything in a conda environment

Start by creating a new conda environment with python <= 3.9, here we use 3.8

```
conda create -n veros-0.2.3 python=3.8
```

and activate it

```
conda activate veros-0.2.3
```

Then install the veros model by running

```
pip install -e path/to/veros
```

As a suggestion, before doing this you can move the `veros` folder inside your conda env folder `.../envs/veros-0.2.3`

Then you'll need to remove the `h5py` package as it was installed without `mpi` support.

```
pip uninstall h5py
```

Then install it again with mpi support

```
conda install -c conda-forge "h5py>=2.9=mpi*"
```

And finally add the `petsc` package

```
conda install -c conda-forge petsc petsc4py
```


### Update the `veros.sh` file in your clusters directory

Inside `.../REA-Veros/clusters/your-cluster/modules/veros.sh` write

```
conda deactivate
conda activate veros-0.2.3
```

# Testing the environment

If you experience issues with running veros try the following tests **in this order**

1. `python .../REA-Veros/tests/test_mpi4py.py` : this checks that `mpi4py` is set correctly.
2. `python .../REA-Veros/tests/test_h5py-mpi.py` : this checks that `h5py` was correctly built with `MPI` support.
3. `cd .../REA-Veros/veros ; . test_veros.sh` : this will launch a short veros run 
