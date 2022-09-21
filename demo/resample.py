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
import logging

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO



def resample(current_folder: str, previous_folder: str):
    '''
    Resamples a new set of trajectories by copying the proper restart files. They are called `e`-init.npy

    Parameters
    ----------
    current_folder : str
        folder for the new iteration
    previous_folder : str
        folder for the previous iteration
    '''
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
    survivors = np.random.choice(ensemble_size,size=ensemble_size,p=weights)

    n_survivors = len(set(survivors))

    logger.log(35, f'Resampling step: {n_survivors} ensemble members survived out of {ensemble_size}')

    cur_d['parents'] = n_survivors
    cur_d['kill_ratio'] = 1 - n_survivors/ensemble_size
    cur_d['previous_folder'] = prev_fold_dir

    # setup the parent attribute and create the init file for each ensemble member
    for i,e in enumerate(cur_d['members']):
        parent = list(prev_d['members'])[survivors[i]]
        cur_d['members'][e]['parent'] = parent

        logger.debug(f'Creating init file for {current_folder}/{e}')
        os.system(f"cp {previous_folder}/{parent}-restart.npy {current_folder}/{e}-init.npy")

    # write the info dict to file
    ut.dict2json(cur_d, f'{current_folder}/info.json')

    logger.log(41, f'Resampling completed in folder = {current_folder}')

if __name__ == '__main__':
    current_folder = sys.argv[1]
    previous_folder = sys.argv[2]

    # deal with logging to telegram
    th = None
    if len(sys.argv) > 4:
        telegram_chat_ID = sys.argv[3]
        telegram_token = sys.argv[4]
        telegram_logging_level = int(sys.argv[5]) if len(sys.argv) > 5 else logging.INFO

        th = ut.new_telegram_handler(telegram_chat_ID, telegram_token, level=telegram_logging_level)

        logger.handlers.append(th)
        logger.debug('Added telegram logger')

    try:
        resample(current_folder, previous_folder)
    finally:
        if th is not None:
            logger.handlers.remove(th)
            logger.info('Removed telegram logger')