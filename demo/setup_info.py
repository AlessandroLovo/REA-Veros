import json

def dict2json(d, filename):
    '''
    Saves a dictionary `d` to a json file `filename`
    '''
    with open(filename, 'w') as j:
        json.dump(d, j, indent=4)

import sys

if __name__ == '__main__':
    folder = sys.argv[1]
    nens = int(sys.argv[2]) # number of ensemble members

    d = {}
    for e in range(nens):
        d[f'e{e+1:03d}'] = {}

    dict2json({'members': d}, f'{folder}/info.json')