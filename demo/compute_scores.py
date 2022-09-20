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



def eval_score(traj):
    return traj[-1,1] - traj[0,1]
    


def compute_score(k, folder):
    folder = folder.rstrip('/')

    d = ut.json2dict(f'{folder}/info.json')

    # compute the scores
    logger.info('Computing scores for each ensemble member')
    escores = []
    for e in d['members']:
        traj = np.load(f'{folder}/{e}-traj.npy')

        score = eval_score(traj)
        escore = np.exp(k*score)
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

    th = None
    if len(sys.argv) > 4:
        telegram_chat_ID = sys.argv[3]
        telegram_token = sys.argv[4]
        telegram_logging_level = int(sys.argv[5]) if len(sys.argv) > 5 else logging.INFO

        th = ut.new_telegram_handler(telegram_chat_ID, telegram_token, level=telegram_logging_level)

        logger.handlers.append(th)
        logger.debug('Added telegram logger')

    try:
        compute_score(k, folder)
    finally:
        if th is not None:
            logger.handlers.remove(th)
            logger.info('Removed telegram logger')
    