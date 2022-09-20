import sys

sys.path.append('../')
import utilities as ut

def setup_info(folder, nens):
    folder = folder.rstrip('/')

    d = {}
    for e in range(nens):
        d[f'e{e+1:03d}'] = {}

    ut.dict2json({'members': d}, f'{folder}/info.json')


if __name__ == '__main__':
    folder = sys.argv[1]
    nens = int(sys.argv[2]) # number of ensemble members

    setup_info(folder, nens)
    