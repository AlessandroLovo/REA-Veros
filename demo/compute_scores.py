import json

def json2dict(filename):
    '''
    Reads a json file `filename` as a dictionary
    '''
    with open(filename, 'r') as j:
        d = json.load(j)
    return d

def dict2json(d, filename):
    '''
    Saves a dictionary `d` to a json file `filename`
    '''
    with open(filename, 'w') as j:
        json.dump(d, j, indent=4)

import numpy as np
import sys

def compute_score(traj):
    return traj[1,-1] - traj[1,0]


if __name__ == '__main__':
    k = float(sys.argv[1])
    folder = sys.argv[2].rstrip('/')

    d = json2dict(f'{folder}/info.json')

    # compute the scores
    scores = []
    for e in d['members']:
        traj = np.load(f'{folder}/{e}-traj.npy')

        score = compute_score(traj)
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
    dict2json(d, f'{folder}/info.json')



