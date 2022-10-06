import os
import subprocess

print('test with os.system')
os.system(". ./test.sh verdi baluga")

print('test with subprocess')
# subprocess.run(['bash', './test.sh', 'verdi', 'baluga'])
subprocess.run("bash ./test.sh verdi baluga".split(' '))