import numpy as np
import xarray as xr
import os
#import h5netcdf
# import matplotlib.pyplot as plt
import sys

# TODO: fix filenames format

def compute_overturning(name:str):
    radius = 6370e3  # Earth radius in m
    degtom = radius / 180. * np.pi
    N = 1
    M = 'infer'
    ot = None
    st = None
    #name = 'REA109i0'
    print(f'compute_overturning for {name = }')

    if os.path.exists('%s-overturning.nc'%name):
        print('Found overturning file')
        try:
            ot = xr.load_dataarray('%s-overturning.nc'%name)
            return ot
        except:
            print('Cound not open overturning file')
    
    print('Computing overturning from averages')

    if M == 'infer':
        print('inferring M')
        if os.path.exists("%s.0000.averages.nc"%name):
            print('Found averages file')
            avgs = xr.load_dataset("%s.0000.averages.nc"%name)
            M = len(avgs.Time)
        else:
            raise FileNotFoundError('Could not find neither overturning nor averages')

    print(f'{M = }')

    t_amoc = np.empty(N*M)
    amoc_all = np.empty((N*M,40,40))
    sss_NA = np.empty(N*M)
    sst_NA = np.empty(N*M)
    sss_SA = np.empty(N*M)
    sst_SA = np.empty(N*M)
    temp_sub_NA = np.empty(N*M)
    temp_sub_SA = np.empty(N*M)
    salt_sub_NA = np.empty(N*M)
    salt_sub_SA = np.empty(N*M)
    rho_sub_NA = np.empty(N*M)
    rho_sub_SA = np.empty(N*M)
    rho_NA = np.empty(N*M)
    rho_SA = np.empty(N*M)
    salt_forc = np.empty(N*M)
    salt_forc_tot = np.empty(N*M)
    salt_tot = np.empty(N*M)
    seaice = np.empty(N*M)

    k=0

    # try:
    #     if ot is None:
    #         ot = xr.load_dataarray('%s-overturning.nc'%name)
    #     return ot
        # if st is None:
        #     st = xr.load_dataset('%s-salt_temp.nc'%name)
        # k = int(len(ot.time)/M)
        # print(f'{k = }')

        # t_amoc[:k*M] = ot.time.values
        # amoc_all[:k*M,:,:] = ot.values

        # sss_NA[:k*M] = st['sss_NA'].values
        # sst_NA[:k*M] = st['sst_NA'].values
        # sss_SA[:k*M] = st['sss_SA'].values
        # sst_SA[:k*M] = st['sst_SA'].values
        # temp_sub_NA[:k*M] = st['temp_sub_NA'].values
        # temp_sub_SA[:k*M] = st['temp_sub_SA'].values
        # salt_sub_NA[:k*M] = st['salt_sub_NA'].values
        # salt_sub_SA[:k*M] = st['salt_sub_SA'].values
        # rho_sub_NA[:k*M] = st['rho_sub_NA'].values
        # rho_sub_SA[:k*M] = st['rho_sub_SA'].values
        # rho_NA[:k*M] = st['rho_NA'].values
        # rho_SA[:k*M] = st['rho_SA'].values
        # salt_forc[:k*M] = st['salt_forc'].values
        # salt_forc_tot[:k*M] = st['salt_forc_tot'].values
        # salt_tot[:k*M] = st['salt_tot'].values
        # seaice[:k*M] = st['seaice'].values
    
    # print(f'{k = }')

    for i in range(k,N):
        print(f'{i + 1 = }/{N}')
        count = str(i); count = count.zfill(4)
        avgs = xr.open_dataset("%s.%s.averages.nc"%(name,count))
        snap = xr.open_dataset("%s.%s.snapshot.nc"%(name,count))
        #print avgs
        #print avgs.Time

        xt = np.asarray(avgs.xt[49:73]); zt = np.asarray(avgs.zt); yu = np.asarray(avgs.yu)
        dxt = np.ones(xt.shape[0]) * (xt[1] - xt[0])
        dzt = np.zeros(zt.shape[0])
        dzt[:-1] = zt[1:] - zt[:-1]
        dzt[-1] = dzt[-2]
        dxt *= degtom
        cosu = np.cos(yu * np.pi / 180.)

        amoc = np.squeeze(compute_eul_moc(avgs.sel(xt=slice(284.,376.)).v, cosu, dxt, dzt))
        #print amoc.shape
        amoc_all[M*i:M*(i+1),:,:] = amoc

        for j in range(M):

            t_amoc[j+i*M] = avgs.Time[j]
            salt_tot[j+i*M] = avgs.isel(Time=j).mean(dim='xt').mean(dim='yt').mean(dim='zt')['salt']
            sst_NA[j+i*M] = avgs.isel(Time=j).isel(zt=-1,yt=slice(25,39)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['temp']
            sst_SA[j+i*M] = avgs.isel(Time=j).isel(zt=-1,yt=slice(9,24)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['temp']
            sss_NA[j+i*M] = avgs.isel(Time=j).isel(zt=-1,yt=slice(25,39)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['salt']
            sss_SA[j+i*M] = avgs.isel(Time=j).isel(zt=-1,yt=slice(9,24)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['salt']
            temp_sub_NA[j+i*M] = avgs.isel(Time=j, yt=slice(25,37), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['temp']
            temp_sub_SA[j+i*M] = avgs.isel(Time=j, yt=slice(9,24), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['temp']
            salt_sub_NA[j+i*M] = avgs.isel(Time=j, yt=slice(25,37), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['salt']
            salt_sub_SA[j+i*M] = avgs.isel(Time=j, yt=slice(9,24), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['salt']

            rho_sub_NA[j+i*M] = snap.isel(Time=j, yt=slice(25,37), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['rho']
            rho_sub_SA[j+i*M] = snap.isel(Time=j, yt=slice(9,24), zt=slice(7,27)).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt').mean(dim='zt')['rho']
            rho_NA[j+i*M] = snap.isel(Time=j, yt=slice(25,37), zt=-1).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['rho']
            rho_SA[j+i*M] = snap.isel(Time=j, yt=slice(9,24), zt=-1).sel(xt=slice(284.,376.)).mean(dim='xt').mean(dim='yt')['rho']
            salt_forc[j+i*M] = snap.isel(Time=j, yt=slice(30,38)).sel(xt=slice(314.,334.)).mean(dim='xt').mean(dim='yt')['forc_salt_surface']
            salt_forc_tot[j+i*M] = snap.isel(Time=j).mean(dim='xt').mean(dim='yt')['forc_salt_surface']
            seaice0 = avgs.isel(Time=j,zt=-1)['temp'].where(avgs.isel(Time=j,zt=-1)['temp']<=-1.8, drop=True)
            seaice0 = seaice0.fillna(10.)
            seaice0 = seaice0.where(seaice0>0., 1.)
            seaice0 = seaice0.where(seaice0!=10., np.nan)
            #print(seaice0.sum(skipna=True).values)
            seaice[j+i*M] = seaice0.sum(skipna=True).values



        ds = xr.DataArray(np.asarray(amoc_all), coords=[t_amoc, zt, yu], dims=['time', 'depth', 'lat'])
        ds2 = xr.Dataset({'salt_tot': (['time'], salt_tot), 'salt_sub_NA': (['time'], salt_sub_NA), 'salt_sub_SA': (['time'], salt_sub_SA), 'temp_sub_NA': (['time'], temp_sub_NA), 'temp_sub_SA': (['time'], temp_sub_SA), 'sst_NA': (['time'], sst_NA), 'sst_SA': (['time'], sst_SA), 'sss_NA': (['time'], sss_NA), 'sss_SA': (['time'], sss_SA), 'rho_sub_NA': (['time'], rho_sub_NA), 'rho_sub_SA': (['time'], rho_sub_SA), 'rho_NA': (['time'], rho_NA), 'rho_SA': (['time'], rho_SA), 'salt_forc': (['time'], salt_forc), 'salt_forc_tot': (['time'], salt_forc_tot), 'seaice': (['time'], seaice)}, coords={'time': t_amoc})

        ds.to_netcdf('%s-overturning.nc'%name)
        ds2.to_netcdf('%s-salt_temp.nc'%name)

    return ds

def compute_eul_moc(v, cosu, dxt, dzt):

    vsf_depth = np.zeros((v.shape[0], v.shape[1], v.shape[2]))
    vsf_depth[:, :, :] += np.cumsum(np.nansum(dxt[np.newaxis, np.newaxis, np.newaxis, :]\
                        * cosu[np.newaxis, np.newaxis, :, np.newaxis]\
                        * v[:, :, :, :], axis=3) * dzt[np.newaxis, :, np.newaxis], axis=1)
    return -vsf_depth



if __name__ == '__main__':
    name = sys.argv[1]
    compute_overturning(name)

