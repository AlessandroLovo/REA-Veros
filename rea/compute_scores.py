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
import os
import subprocess

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO


### The function that computes the score starting from a segment of trajectory ###

def relative_score(traj) -> float:
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

window_width = 1
def absolute_score(traj, initial=False) -> float:
    if initial:
        return np.mean(traj[:window_width,1])
    return np.mean(traj[-window_width:,1])
    

def compute_score(k: float=0.0, folder: str=None, mode='relative', from_cum=True, telescopic_canceling=False, make_traj_script=None):
    '''
    Computes the scores and weights for each ensemble member in a folder

    Parameters
    ----------
    k : float
        biasing parameter, conjugated to the score. The higher the values, the sharper the selection. k=0 means uniform weight to all trajectories regardless of the score
    folder : str
        folder where the ensemble is located. Must contain a properly initialized `info.json` file
    from_cum : bool
        Whether to compute the score directly or from the cumulative score difference. The latter is useful if it is easier to compute the cumulative score, for instance when there is a time average.
    telescopic_canceling : bool
        Whether to enable telescopic canceling of the score terms. This parameter is irrelevant if the whole run is performed at constant `k`, but it produces different effects if `k` is changed.
        If True, the final weight of a trajectory will be simply
            `` exp(k_1 V_0 - k_n V_n) * cum_norm_factor ``
        However, there will be a weird resampling step at the discontinuity in `k`
        If False, there is no weirdness when k changes, but the weight of the trajectory will not telescopically cancel:
            `` exp(\sum_{i=1}^n k_n(V_{i-1} - V_i) ) * cum_norm_factor
    '''
    # get the info dictionary
    folder = folder.rstrip('/')

    d = ut.json2dict(f'{folder}/info.json')

    d['k'] = k

    if mode == 'absolute':
        from_cum = False
        eval_score_func = absolute_score
    elif mode == 'relative':
        eval_score_func = relative_score
    else:
        raise ValueError(f'unrecognized {mode = }')

    # compute the scores
    logger.info('Computing scores for each ensemble member')
    escores = []
    for ename, e in d['members'].items():
        traj = f'{folder}/{ename}-traj.npy'
        if not os.path.exists(traj):
            if make_traj_script:
                subprocess.run(f'python {make_traj_script} {folder}/{ename}'.split(' '))
            else:
                raise RuntimeError('Trajectory not found and script for creating it not provided')
        traj = np.load(traj)

        # This implementation is robust against different values of k along the realization of the algorithm
        if from_cum: # compute first the cumulative score. This is the way to go if the score involves a time average
            if 'cum_score_i' not in e:
                e['cum_score_i'] = absolute_score(traj, initial=True)
                e['cum_log_escore_i'] = k*e['cum_score_i']
            cum_score_f = absolute_score(traj)
            score = cum_score_f - e['cum_score_i']
            if telescopic_canceling:
                cum_log_escore_f = k*cum_score_f
                escore = np.exp(cum_log_escore_f - e['cum_log_escore_i'])
            else:
                cum_log_escore_f = e['cum_log_escore_i'] + k*score
                escore = np.exp(k*score)

        else:
            if 'cum_score_i' not in e: # TODO: maybe this is not the best approach
                e['cum_score_i'] = 0
                e['cum_log_escore_i'] = 0
            score = eval_score_func(traj)
            cum_score_f = e['cum_score_i'] + score
            if telescopic_canceling:
                cum_log_escore_f = k*cum_score_f
                escore = np.exp(cum_log_escore_f - e['cum_log_escore_i'])
            else:
                escore = np.exp(k*score) # the exponentiated score
                cum_log_escore_f = e['cum_log_escore_i'] + k*score # that is the same as + np.log(escore)
        
        escores.append(escore)
        e['score'] = score
        e['escore'] = escore
        e['cum_score_f'] = cum_score_f
        e['cum_log_escore_f'] = cum_log_escore_f

    # normalize the scores
    logger.info('Normalizing scores')
    escores = np.array(escores)
    norm_factor = np.sum(escores)
    escores /= norm_factor

    # save in the dictionary
    d['norm_factor'] = norm_factor/len(escores) # in the papers the normalization factor is defined as the average escore, not the sum
    if 'cum_log_norm_factor_i' not in d:
        d['cum_log_norm_factor_i'] = 0
    d['cum_log_norm_factor_f'] = d['cum_log_norm_factor_i'] + np.log(d['norm_factor'])
    for i,e in enumerate(d['members']):
        d['members'][e]['weight'] = escores[i]

    # save the dictionary to file
    ut.dict2json(d, f'{folder}/info.json')

    logger.log(41, f'Computed scores for {folder = }')


if __name__ == '__main__':
    k = float(sys.argv[1])
    folder = sys.argv[2]

    # get kwargs from the environment
    kwarg2envvar = {
        'mode': 'REA_CS_MODE',
        'make_traj_script': 'REA_MAKE_TRAJ_SCRIPT',
    }
    kwargs = {}
    for k,ev in kwarg2envvar.items():
        try:
            v = os.environ[ev]
            if v == '':
                v = None
            kwargs[k] = v
        except KeyError:
            logger.warning(f'{ev} is not set: using default value for {k}')

    with ut.TelegramLogger(logger, *(sys.argv[3:])):
        compute_score(k, folder, **kwargs)
    
