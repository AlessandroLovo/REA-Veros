import os
import sys

folder = sys.argv[1]

for filename in os.listdir(folder):
    if filename.startswith('REA1'):
        num = int(filename[4:6]) + 1
        nf = f'e{num:02d}{filename[8:]}'
        print(filename, nf)
