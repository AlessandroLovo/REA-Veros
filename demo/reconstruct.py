import numpy as np
import sys
# import os

sys.path.append('../')
import utilities as ut

def reconstruct(last_folder):
    last_folder = last_folder.rstrip('.')
    root_folder = '.'
    if '/' in last_folder:
        root_folder, last_folder = last_folder.rsplit('/',1)

    d = {'last_folder': last_folder, 'members': {}, 'folders': [last_folder]}

    info = ut.json2dict(f'{root_folder}/{last_folder}/info.json')
    
    parents = set([])
    for i,e in enumerate(info['members']):
        parent = info['members'][e]['parent']
        d['members'][f'r{i+1:03d}'] = [e, parent]
        parents.add(parent)
    
    while True:
        prev_folder = info['previous_folder']
        print(f'Opening {prev_folder}')

        info = ut.json2dict(f'{root_folder}/{prev_folder}/info.json')
        d['folders'].append(prev_folder)

        if 'previous_folder' not in info:
            print('Reached root')
            break

        # retrieve the grandparents
        grand_parents = {p: info['members'][p]['parent'] for p in parents}

        # assign the grandparent to each ensemble member
        for parent_list in d['members'].values():
            parent_list.append(grand_parents[parent_list[-1]])

        # move back one step by setting the new parents as the now grandparents
        parents = set(grand_parents.values())

    print('Reversing time')

    d['folders'] = d['folders'][::-1]
    for e, parent_list in d['members'].items():
        d['members'][e] = parent_list[::-1]

    print('Saving')

    ut.dict2json(d, f'{root_folder}/reconstructed.json')

    print('\n\nDONE\n\n')

if __name__ == '__main__':
    last_folder = sys.argv[1]
    
    reconstruct(last_folder)
