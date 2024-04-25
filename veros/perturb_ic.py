import numpy as np
import h5py
import sys
import os

def perturb_ic(source, destination=None):
    '''
    Perturbs the initial conditions by overwriting the restart file. It acts on the temperature field T and and salt field S, independently on each grid point:

    T -> T + T*0.001*normal(0,1)
    S -> S + 0.002*normal(0,1)

    T is in degrees C, S is in g/kg
    Rough typical values are T ~ 5 +/- 8 and S ~ 34 +/- 0.2 

    Parameters
    ----------
    filename : str
        path to the restart file
    '''
    if destination is None:
        destination = source # overwrite mode
    if destination != source:
        os.system(f'cp {source} {destination}')

    f = h5py.File(destination, 'r+')

    #print(f.keys())
    snap = f['snapshot']
    #print(snap.keys())

    salt = snap['salt'][:]
    temp = snap['temp'][:]

    pert_salt = np.random.normal(loc=0., scale=1.0, size=(94,44,40,3))
    pert_temp = np.random.normal(loc=0., scale=1.0, size=(94,44,40,3))

    salt[...] = salt + 0.002*pert_salt
    salt[salt<=10.]=0.
    del snap['salt']
    snap.create_dataset('salt', data=salt)

    temp[...] = temp + temp*0.001*pert_temp
    del snap['temp']
    snap.create_dataset('temp', data=temp)


    f.close()


if __name__ == '__main__':
    source = f'{sys.argv[1]}.0000.restart.h5'
    destination = f'{sys.argv[2]}-init.h5'
    perturb_ic(source, destination)
