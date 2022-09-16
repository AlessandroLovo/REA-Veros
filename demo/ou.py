import numpy as np
import sys

dt = 0.01
mu = 0
theta = 1
sigma = 0.5

def update(t,x):
    dx = (mu - x)*theta*dt + np.sqrt(2*sigma*dt)*np.random.standard_normal()
    return t + dt, x + dx

def run(niter, prefix, restart_file=None):
    if restart_file is not None:
        ic = tuple(np.load(restart_file))
        if len(ic) != 2:
            raise ValueError('Incompatible restart file format')
    else:
        ic = (0,0.5)

    traj = []
    traj.append(ic)

    for i in range(niter):
        traj.append(update(*(traj[-1])))

    traj = np.array(traj)

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
    