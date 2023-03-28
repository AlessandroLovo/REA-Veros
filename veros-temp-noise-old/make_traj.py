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
    # we want to minimize the amoc strength, so we multiply the amoc by -1
    traj = traj*np.array([1,-1]) # we don't touch the time axis
    print(f'{traj.shape = }')
    np.save(f'{prefix}-traj.npy', traj)

if __name__ == '__main__':
    prefix = sys.argv[1]
    make_traj(prefix)