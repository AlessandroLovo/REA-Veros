# '''
# Created on 2022-09-19

# @author: Alessandro Lovo
# '''
'''
This module allows to reconstruct the trajectories from an already performed run.
It recursively attaches the ancestors to the trajectories and computes the unbiasing factors

When running from terminal:
```
python reconstruct.py <last iteration folder>
'''
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



def reconstruct(last_folder: str, write=False):
    '''
    Recontructs trajectories and compute their unbiasing weights

    Parameters
    ----------
    last_folder : str
        folder with the last step of the GKTL algorithm
    write : bool, optional
        Whether to write the result to a `root_folder`/recontructed.json, where `root_folder` is the parent of `last_folder`, by default False

    Returns
    -------
    dict
        {
            'last_folder',
            'cum_log_norm_factor': cumulative log of the normalization factor
            'members' : list of ensemble members, each contains
                'cum_score': cumulative score
                'cum_log_escore': cumulative log of the exponential score, if the exponentiation function is a constant `k` in time it is just `k`*`cum_score`
                'weight': the unbiasing weight for this ensemble member, namely its likelihood of actually happening in the non-biased dynamics.
                'ancestry': list of parents starting from the furthest in time
            'folders': list of the folders containg the parents, starting from the furthest in time, i.e. time goes forward in the list
            'independent_parents': list of the number of independent reconstructed ancestors at that step of the algorithm
        }
    '''
    last_folder = last_folder.rstrip('.')
    root_folder = '.'
    if '/' in last_folder:
        root_folder, last_folder = last_folder.rsplit('/',1)

    ### IMPORTANT ###
    # Of the last folder we take only the starting point, not the propagated trajectory
    # That's why we don't include it in the list and the cumulative sums start from 0

    d = {'last_folder': last_folder, 'cum_log_norm_factor': 0.0, 'members': {}, 'folders': [], 'independent_parents': []}

    # load the info file of the current directory
    info = ut.json2dict(f'{root_folder}/{last_folder}/info.json')
    
    # collect all independent parents
    parents = set([])
    for i,e in enumerate(info['members'].values()):
        parent = e['parent']
        d['members'][f'r{i+1:03d}']= {'cum_score': 0.0, 'cum_log_escore': 0.0, 'ancestry': [parent]}
        parents.add(parent)
    
    while True:
        prev_folder = info['previous_folder']
        logger.info(f'Opening {prev_folder}')

        # info file of the folder of the parents
        info = ut.json2dict(f'{root_folder}/{prev_folder}/info.json')
        d['folders'].append(prev_folder)
        d['cum_log_norm_factor'] += np.log(info['norm_factor'])
        d['independent_parents'].append(len(parents))

        # add the score of the parent to the total score of this member
        for e in d['members'].values():
            parent = e['ancestry'][-1]
            e['cum_score'] += info['members'][parent]['score']
            e['cum_log_escore'] += np.log(info['members'][parent]['escore'])

        # detect if we reached the last ancestor
        if 'previous_folder' not in info or not info['previous_folder']:
            logger.info('Reached root')
            break

        # retrieve the grandparents
        grand_parents = {p: info['members'][p]['parent'] for p in parents}

        # assign the grandparent to each ensemble member
        for e in d['members'].values():
            e['ancestry'].append(grand_parents[e['ancestry'][-1]])

        # move back one step by setting the new parents as the now grandparents
        parents = set(grand_parents.values())

    # reverse the lists so time goes forward with them
    logger.info('Reversing time')

    d['folders'] = d['folders'][::-1]
    d['independent_parents'] = d['independent_parents'][::-1]
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
