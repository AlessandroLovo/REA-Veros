# '''
# Created on 2022-09-15

# @author: Alessandro Lovo
# '''
'''
This module simulates a 1D Ornstein-Uhlenmbeck process.

When running from terminal:
```
python ou.py <n_iterations> <prefix> [<restart file>]
```
`prefix` can contain '/', if the folder doesn't exist, it is created
`restart file` contains the initial conditions for the trajectory. If not provided the trajectory starts at 0 at time 0.

The script will save a trajectory file `prefix`traj.npy as [(t_0,x_0), ..., (t_n,x_n)] and a restart file `prefix`restart.npy that contains (t_n,x_n)
'''
from pathlib import Path
import numpy as np
import sys

dt = 0.01
mu = 0
theta = 1
sigma = 0.5

def update(t,x):
    dx = (mu - x)*theta*dt + np.sqrt(2*sigma*dt)*np.random.standard_normal()
    return t + dt, x + dx

def run(niter: int, prefix: str, restart_file: str=None):
    if restart_file is not None:
        ic = tuple(np.load(restart_file))
        if len(ic) != 2:
            raise ValueError('Incompatible restart file format')
    else:
        ic = (0.,0.)

    traj = []
    traj.append(ic)

    for i in range(niter):
        traj.append(update(*(traj[-1])))

    traj = np.array(traj)

    # create the folder if it doesn't exist
    if '/' in prefix:
        folder = Path(prefix.rsplit('/',1)[0])
        if not folder.exists():
            folder.mkdir(parents=True)

    np.save(f'{prefix}traj.npy',traj)

    np.save(f'{prefix}restart.npy',traj[-1])


if __name__ == '__main__':
    # print('Starting')
    niter = int(sys.argv[1])
    prefix = sys.argv[2]
    restart_file = None

    if len(sys.argv) > 3:
        restart_file = sys.argv[3]

    run(niter, prefix, restart_file)
    