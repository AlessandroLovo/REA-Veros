# '''
# Created on 2022-09-27

# @author: Alessandro Lovo
# '''
'''
This module simulates a 1D Gaussian process in a double well potential.

When running from terminal:
```
python dw.py <n_iterations> <prefix> [<restart file>]
```
`prefix` can contain '/', if the folder doesn't exist, it is created
`restart file` contains the initial conditions for the trajectory. If not provided the trajectory starts at 0 at time 0.

The script will save a trajectory file `prefix`traj.npy as [(t_0,x_0), ..., (t_n,x_n)] and a restart file `prefix`restart.npy that contains (t_n,x_n)
'''
from pathlib import Path
import numpy as np
import sys
import os

dt = 0.01
sigma = 0.8
h = 1.0
w = 1.0

# the potential is
# U(x) = h*(x**2 - w**2)**2/w**4
# It is 0 in x = +/- w (the two wells) and U(0) = h (the local maximum of the potential) and the hight of the barrier to overcome

def update(t,x):
    dx = -4*x*(x**2 - w**2)/w**4*dt + sigma*np.sqrt(dt)*np.random.standard_normal()
    return t + dt, x + dx

def run(niter: int, restart_file: str=None):
    if restart_file is not None:
        ic = tuple(np.load(restart_file))
        if len(ic) != 2:
            raise ValueError('Incompatible restart file format')
    else:
        ic = (0.,-w)

    traj = []
    traj.append(ic)

    for i in range(niter):
        traj.append(update(*(traj[-1])))

    return np.array(traj)


if __name__ == '__main__':
    # print('Starting')
    niter = int(sys.argv[1])
    prefix = sys.argv[2]
    restart_file = None

    if len(sys.argv) > 3:
        restart_file = sys.argv[3]

    if restart_file is None:
        restart_file = f'{prefix}-init.npy'
        if not os.path.exists(restart_file):
            restart_file = None

    traj = run(niter, restart_file)

    # create the folder if it doesn't exist
    if '/' in prefix:
        folder = Path(prefix.rsplit('/',1)[0])
        if not folder.exists():
            folder.mkdir(parents=True)

    np.save(f'{prefix}traj.npy',traj)

    np.save(f'{prefix}restart.npy',traj[-1])
    