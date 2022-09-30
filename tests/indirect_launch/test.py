import sys
import time

if __name__ == '__main__':
    print(sys.argv)
    time.sleep(3)
    for i,v in enumerate(sys.argv):
        print(i,v)
        if i == 2:
            raise ValueError