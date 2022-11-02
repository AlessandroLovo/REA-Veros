import perturb_ic as pic
import sys
import os
from pathlib import Path

def make_ensemble(source, destination_folder, nens=50):
    df = Path(destination_folder)
    if not df.exists():
        df.mkdir(parents=True, exist_ok=True)

    for e in range(nens):
        pic.perturb_ic(source=source, destination=df / f"e{e+1:0{len(str(nens))}d}-init.h5")

if __name__ == '__main__':
    source = sys.argv[1]
    destination_folder=sys.argv[2]
    nens=int(sys.argv[3])
    make_ensemble(source, destination_folder, nens)