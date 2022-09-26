# '''
# Created on 2022-09-15

# @author: Alessandro Lovo
# '''
'''
This script sets up the info dictionary for a new step of the GKTL algorithm

When running from terminal:
```
python setup_info.py <folder> <n_ensemble_members>
```
`folder` is where we want to create the `info.json` file
'''

import sys

sys.path.append('../')
import general_purpose.utilities as ut

def setup_info(nens: int):
    '''
    Parameters
    ----------
    nens : int
        number of ensemble members

    Returns
    ------
    {
        'members': {f'e{e+1:03d}': {} for e in range(`nens`)}
    }
    '''
    return {'members': {f'e{e+1:0{len(str(nens))}d}': {} for e in range(nens)}}


if __name__ == '__main__':
    folder = sys.argv[1]
    folder = folder.rstrip('/')
    
    nens = int(sys.argv[2]) # number of ensemble members

    ut.dict2json(setup_info(nens), f'{folder}/info.json')
    
    