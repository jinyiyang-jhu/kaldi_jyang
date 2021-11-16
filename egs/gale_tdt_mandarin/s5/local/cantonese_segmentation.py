# Python3

import pycantonese
import sys

if __name__ == '__main__':
    for i in sys.stdin:
        line = ' '.join(pycantonese.segment(i.strip()))
        print(line)