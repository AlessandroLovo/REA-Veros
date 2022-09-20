import numpy as np
import sys

sys.path.append('../')
import utilities as ut

def eval_score(traj):
    return traj[1,-1] - traj[1,0]

def compute_score(k, folder):
    folder = folder.rstrip('/')

    d = ut.json2dict(f'{folder}/info.json')

    # compute the scores
    scores = []
    for e in d['members']:
        traj = np.load(f'{folder}/{e}-traj.npy')

        score = eval_score(traj)
        scores.append(score)
        d['members'][e]['score'] = score

    # normalize the scores
    scores = np.array(scores)
    scores = np.exp(k*scores)
    norm_factor = np.sum(scores)
    scores /= norm_factor

    # save in the dictionary
    d['norm_factor'] = norm_factor
    for i,e in enumerate(d['members']):
        d['members'][e]['weight'] = scores[i]

    # save the dictionary to file
    ut.dict2json(d, f'{folder}/info.json')


if __name__ == '__main__':
    k = float(sys.argv[1])
    folder = sys.argv[2]

    compute_score(k, folder)
    