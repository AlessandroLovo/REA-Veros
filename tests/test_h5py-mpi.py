from mpi4py import MPI
import h5py
import os

comm = MPI.COMM_WORLD      # Use the world communicator
mpi_rank = comm.Get_rank() # The process ID (integer 0-41 for a 42-process job)
mpi_size = comm.Get_size() # Total amount of ranks

destination = 'test_h5py-mpi_output.h5'

print(f'Attempting to write to {destination}')
with h5py.File(destination, 'w', driver='mpio', comm=MPI.COMM_WORLD) as f:
    dset = f.create_dataset('test', (42,), dtype='i')
    dset[mpi_rank] = mpi_rank

comm.Barrier()

if (mpi_rank == 0):
    print('42 MPI ranks have finished writing!')

print('Removing output file')
os.remove(destination)