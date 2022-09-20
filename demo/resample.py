import numpy as np
import sys
import os

sys.path.append('../')
import general_purpose.utilities as ut

def resample(current_folder, previous_folder):
    current_folder = current_folder.rstrip('/')
    previous_folder = previous_folder.rstrip('/')

    prev_fold_dir = previous_folder.split('/')[-1]

    cur_d = ut.json2dict(f'{current_folder}/info.json')
    prev_d = ut.json2dict(f'{previous_folder}/info.json')

    ensemble_size = len(prev_d['members'])

    # retrieve the weights
    weights = [e['weight'] for e in prev_d['members'].values()]

    # apply the selection
    survivors = np.random.choice(ensemble_size,size=ensemble_size,p=weights)

    cur_d['parents'] = len(set(survivors))
    cur_d['previous_folder'] = prev_fold_dir

    # setup the parent attribute and create the init file for each ensemble member
    for i,e in enumerate(cur_d['members']):
        parent = list(prev_d['members'])[survivors[i]]
        cur_d['members'][e]['parent'] = parent

        os.system(f"cp {previous_folder}/{parent}-restart.npy {current_folder}/{e}-init.npy")

    # write the info dict to file
    ut.dict2json(cur_d, f'{current_folder}/info.json')


if __name__ == '__main__':
    current_folder = sys.argv[1]
    previous_folder = sys.argv[2]

    resample(current_folder, previous_folder)
    