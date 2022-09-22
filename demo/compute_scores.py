# '''
# Created on 2022-09-15

# @author: Alessandro Lovo
# '''
'''
This script computes the score of each ensemble member for a given timestep.
The scores are then used to compute the weights that will be used for resampling trajectories

When running from terminal:
```
python compute_scores.py <k> <folder> [<telegram chat ID> <telegram bot token>] [<telegram logging level>]
```
'''

import numpy as np
import logging
import sys

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO


### The function that computes the score starting from a segment of trajectory ###

def eval_score(traj):
    '''
    Just takes the difference between the last and first x coordinate of the trajectory

    Parameters
    ----------
    traj : np.ndarray with shape (N,2)
        trajectory consisting of N (t,x) points

    Returns
    -------
    float
        x[-1] - x[0]
    '''
    return traj[-1,1] - traj[0,1]
    


def compute_score(k: float=0.0, folder: str=None):
    '''
    Computes the scores and weights for each ensemble member in a folder

    Parameters
    ----------
    k : float
        biasing parameter, conjugated to the score. The higher the values, the sharper the selection. k=0 means uniform weight to all trajectories regardless of the score
    folder : str
        folder where the ensemble is located. Must contain a properly initialized `info.json` file
    '''
    # get the info dictionary
    folder = folder.rstrip('/')

    d = ut.json2dict(f'{folder}/info.json')

    # compute the scores
    logger.info('Computing scores for each ensemble member')
    escores = []
    for e in d['members']:
        traj = np.load(f'{folder}/{e}-traj.npy')

        score = eval_score(traj)
        escore = np.exp(k*score) # the exponentiated score
        escores.append(escore)
        d['members'][e]['score'] = score
        d['members'][e]['escore'] = escore

    # normalize the scores
    logger.info('Normalizing scores')
    escores = np.array(escores)
    norm_factor = np.sum(escores)
    escores /= norm_factor

    # save in the dictionary
    d['norm_factor'] = norm_factor/len(escores) # in the papaers the normalization factor is defined as the average escore, not the sum
    for i,e in enumerate(d['members']):
        d['members'][e]['weight'] = escores[i]

    # save the dictionary to file
    ut.dict2json(d, f'{folder}/info.json')

    logger.log(41, f'Computed scores for {folder = }')


if __name__ == '__main__':
    k = float(sys.argv[1])
    folder = sys.argv[2]

    with ut.TelegramLogger(logger, *(sys.argv[3:])):
        compute_score(k, folder)
    