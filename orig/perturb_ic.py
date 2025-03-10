import matplotlib.pyplot as pl
import numpy as np
import xarray as xr
import h5py
import matplotlib as mpl
import sys

def MAIN():
        a = sys.argv[1]
        perturb_ic(a)
        #test_pert()

        pl.show()

def test_pert():
        f = h5py.File('s720ur2bP0.0100.restart.h5', 'r+')
        f0 = h5py.File('s720ur2b.0100.restart.h5', 'r+')

        snap = f['snapshot']
        snap0 = f0['snapshot']

        temp = snap['temp'][:]
        temp0 = snap0['temp'][:]
        
        salt = snap['salt'][:]
        salt0 = snap0['salt'][:]

        fig=pl.figure()
        pl.pcolormesh(temp[:,:,-1,0]-temp0[:,:,-1,0])
        pl.colorbar()
        
        fig=pl.figure()
        pl.pcolormesh(salt[:,:,-1,0]-salt0[:,:,-1,0])
        pl.colorbar()
        
        fig=pl.figure()
        pl.pcolormesh(salt[:,:,-20,0]-salt0[:,:,-20,0])
        pl.colorbar()


def perturb_ic(a):

        f = h5py.File('s720ur2b.0%s.restartP.h5'%a, 'r+')

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
        MAIN()
