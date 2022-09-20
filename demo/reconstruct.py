import numpy as np
import sys
# import os
import logging

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO



def reconstruct(last_folder, write=False):
    last_folder = last_folder.rstrip('.')
    root_folder = '.'
    if '/' in last_folder:
        root_folder, last_folder = last_folder.rsplit('/',1)

    ### IMPORTANT ###
    # Of the last folder we take only the starting point, not the propagated trajectory
    # That's why we don't include it in the list and the cumulative sums start from 0

    d = {'last_folder': last_folder, 'cum_log_norm_factor': 0.0, 'members': {}, 'folders': [], 'independent_parents': []}

    info = ut.json2dict(f'{root_folder}/{last_folder}/info.json')
    
    parents = set([])
    for i,e in enumerate(info['members'].values()):
        parent = e['parent']
        d['members'][f'r{i+1:03d}']= {'cum_score': 0.0, 'cum_log_escore': 0.0, 'ancestry': [parent]}
        parents.add(parent)
    
    while True:
        prev_folder = info['previous_folder']
        logger.info(f'Opening {prev_folder}')

        info = ut.json2dict(f'{root_folder}/{prev_folder}/info.json')
        d['folders'].append(prev_folder)
        d['cum_log_norm_factor'] += np.log(info['norm_factor'])
        d['independent_parents'].append(len(parents))

        # add the score of the parent to the total score of this member
        for e in d['members'].values():
            parent = e['ancestry'][-1]
            e['cum_score'] += info['members'][parent]['score']
            e['cum_log_escore'] += np.log(info['members'][parent]['escore'])

        if 'previous_folder' not in info:
            logger.info('Reached root')
            break

        # retrieve the grandparents
        grand_parents = {p: info['members'][p]['parent'] for p in parents}

        # assign the grandparent to each ensemble member
        for e in d['members'].values():
            e['ancestry'].append(grand_parents[e['ancestry'][-1]])

        # move back one step by setting the new parents as the now grandparents
        parents = set(grand_parents.values())

    logger.info('Reversing time')

    d['folders'] = d['folders'][::-1]
    d['parents'] = d['parents'][::-1]
    for e in d['members'].values():
        e['ancestry'] = e['ancestry'][::-1]

        # assign the weight of each trajectory for computing probabilities
        e['weight'] = np.exp(d['cum_log_norm_factor'] - e['cum_log_escore'])

    if write:
        logger.info('Saving')
        ut.dict2json(d, f'{root_folder}/reconstructed.json')

    logger.log(35,'DONE')

    return d

if __name__ == '__main__':
    last_folder = sys.argv[1]
    
    reconstruct(last_folder, write=True)
