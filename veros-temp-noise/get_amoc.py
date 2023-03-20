import numpy as np
import xarray as xr

d0 = 0; d1 = 25 ### 25 is roughly 500-600 meters depth -> Below wind-driven maximum

# d = 21 is index for 1000m depth.
# lat = 29 is index for 30N

def observable(ot,i):
	return ot.isel(time=i, depth=slice(d0,d1), lat=slice(24,40)).max().values/1000000.
	
def amoc_timeseries(ot):
    t_amoc = []; amoc = []
    for i in range(len(ot.time)):
        t_amoc.append(ot.time[i]/360.)
        amoc.append(observable(ot,i))
    return t_amoc, amoc

# deprecated for filename conflicts
def get_all(N=50):
    amoc = []
    t = []
    for i in range(N):
        x = xr.open_dataarray("overturning_%s.nc"%str(100+i))
        t_amoc0, amoc0 = amoc_timeseries(x)
        amoc.append(amoc0); t.append(t_amoc0)

    return t, amoc
