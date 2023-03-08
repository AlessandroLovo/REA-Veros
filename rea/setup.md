# Setting up the rare event algorithm

In this file we show how to properly setup an environment for running the rare event algorithm in this repo

## Conda environment

The simplest way to do this is to create a new conda environment

```
conda create -n rea
```

and activate it

```
conda activate rea
```

Then install the necessary packages

```
conda install -c conda-forge xarray scipy h5py h5netcdf
```

and also the one for logging to telegram

```
pip install python-telegram-handler
```

### Update the `python.sh` file in your clusters directory

Inside `.../REA-Veros/clusters/your-cluster/modules/python.sh` write

```
conda deactivate
conda activate rea
```