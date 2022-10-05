import numpy as np

def say_hi():
    print('hi!')

def save_to_file(a, filename):
    np.save(filename, a)