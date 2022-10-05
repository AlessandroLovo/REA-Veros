import mod
import numpy as np

import sys

filename = sys.argv[1]

mod.save_to_file(np.arange(2), filename)