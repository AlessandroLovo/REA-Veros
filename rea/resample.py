# '''
# Created on 2022-09-15

# @author: Alessandro Lovo
# '''
'''
This script resamples new initial conditions according to the weights in the info file

When running from terminal:
```
python resample.py <current_folder> <previous_folder> [<telegram chat ID> <telegram bot token>] [<telegram logging level>]
```
`current_folder` is the folder where we want to create the new starting conditions, `previous_folder` is the one with the last step of ensemble members.

The script will write to the `info.json` file. If it doesn't find it, it will create it using the `setup_info.py` script.  
'''
import numpy as np
import sys
import os
import subprocess
import logging

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO
# logger.level = logging.DEBUG

def draw(weights:np.ndarray, method='choice') -> np.ndarray:
    weights = np.array(weights)
    n = len(weights)
    # check if weights sum to 1
    s = np.sum(weights)
    if np.abs(s - 1) > 1e-7:
        logger.warning('Weights do not add up to 1: renormalizing them')
        weights /= s
    
    if method == 'choice':
        return np.random.choice(n, size=n, p=weights,replace=True,)
    elif method == 'reduced_variance':
        # number of tentative clones for each member
        clones = (n*weights + np.random.uniform(0,1,size=n)).astype(int)
        logger.debug(f'tentative {clones = }')
        survivors = []
        for i,c in enumerate(clones):
            survivors += [i]*c
        logger.debug(f'tentative {survivors = }')

        n_extra_clones = len(survivors) - n

        if n_extra_clones > 0:
            # we kill the extra clones
            logger.debug(f'killing the extra {n_extra_clones} clones')
            survivors = np.random.permutation(survivors)[:n]
        elif n_extra_clones < 0:
            # we clone the missing ones from the survivors
            logger.debug(f'Cloning {-n_extra_clones} extra trajectories')
            survivors += list(np.random.choice(survivors, size=-n_extra_clones, replace=True))

        if len(survivors) != n:
            raise RuntimeError('Something went very wrong when drawing the survivors')
        
    else:
        raise ValueError(f'Unrecognized {method = }')

    return np.array(survivors)


def resample(current_folder: str, previous_folder: str, cloning_script: str='../demo/clone.sh'):
    '''
    Resamples a new set of trajectories by copying the proper restart files. They are called `e`-init.npy

    Parameters
    ----------
    current_folder : str
        folder for the new iteration
    previous_folder : str
        folder for the previous iteration
    '''
    if cloning_script.endswith('.py'): # python script
        cloning_script = f'python {cloning_script}'
    else: # shell script
        cloning_script = f'bash {cloning_script}'

    current_folder = current_folder.rstrip('/')
    previous_folder = previous_folder.rstrip('/')

    prev_fold_dir = previous_folder.split('/')[-1]

    prev_d = ut.json2dict(f'{previous_folder}/info.json')
    ensemble_size = len(prev_d['members'])
    
    try:
        cur_d = ut.json2dict(f'{current_folder}/info.json')
    except FileNotFoundError:
    # create info file for this folder if it doesn't exist
        import setup_info
        logger.warning(f'Info dictionary not found in {current_folder}: creating a new one')
        cur_d = setup_info.setup_info(ensemble_size)
    
    logger.info('Loaded info dictionaries')

    # retrieve the weights
    weights = [e['weight'] for e in prev_d['members'].values()]

    # apply the selection
    survivors = draw(weights, method='reduced_variance')

    n_survivors = len(set(survivors))

    logger.log(35, f'Resampling step: {n_survivors} ensemble members survived out of {ensemble_size}')

    cur_d['parents'] = n_survivors
    cur_d['kill_ratio'] = 1 - n_survivors/ensemble_size
    cur_d['previous_folder'] = prev_fold_dir
    cur_d['cum_log_norm_factor_i'] = prev_d['cum_log_norm_factor_f']

    # setup the parent attribute and create the init file for each ensemble member
    for i,e in enumerate(cur_d['members']):
        parent = list(prev_d['members'])[survivors[i]]
        cur_d['members'][e]['parent'] = parent
        cur_d['members'][e]['cum_score_i'] = prev_d['members'][parent]['cum_score_f']
        cur_d['members'][e]['cum_log_escore_i'] = prev_d['members'][parent]['cum_log_escore_f']

        logger.debug(f'Creating init file for {current_folder}/{e}')
        # os.system(f"echo {cloning_script} {previous_folder}/{parent} {current_folder}/{e}")
        subprocess.run(f"{cloning_script} {previous_folder}/{parent} {current_folder}/{e}".split(' '))

    # write the info dict to file
    ut.dict2json(cur_d, f'{current_folder}/info.json')

    logger.log(41, f'Resampling completed in folder = {current_folder}')

if __name__ == '__main__':
    current_folder = sys.argv[1]
    previous_folder = sys.argv[2]
    cloning_script = sys.argv[3]

    with ut.TelegramLogger(logger, *(sys.argv[4:])):
        resample(current_folder, previous_folder, cloning_script)