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



def resample(current_folder, previous_folder):
    current_folder = current_folder.rstrip('/')
    previous_folder = previous_folder.rstrip('/')

    prev_fold_dir = previous_folder.split('/')[-1]

    cur_d = ut.json2dict(f'{current_folder}/info.json')
    prev_d = ut.json2dict(f'{previous_folder}/info.json')

    logger.info('Loaded info dictionaries')

    ensemble_size = len(prev_d['members'])

    # retrieve the weights
    weights = [e['weight'] for e in prev_d['members'].values()]

    # apply the selection
    survivors = np.random.choice(ensemble_size,size=ensemble_size,p=weights)

    n_survivors = len(set(survivors))

    logger.log(35, f'Resampling step: {n_survivors} ensemble members survived out of {ensemble_size}')

    cur_d['parents'] = n_survivors
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