import numpy as np
import xarray as xr

import calc_overturning as co
import get_amoc as ga

import sys

def make_traj(prefix:str):

    # compute overturning
    overturning = co.compute_overturning(prefix)

    # compute the amoc and save it to traj
    t, amoc = ga.amoc_timeseries(overturning)

    traj = np.array([t,amoc]).T
    print(f'{traj.shape = }')
    np.save(f'{prefix}-traj.npy', traj)

if __name__ == '__main__':
    prefix = sys.argv[1]
    make_traj(prefix)