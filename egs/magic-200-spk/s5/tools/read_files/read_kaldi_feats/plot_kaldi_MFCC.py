#!/usr/bin/python3
# coding: utf-8

# In[ ]:

import matplotlib.pyplot as plt
import argparse
from read_kaldi_MFCC import readMFCC

def readMFCC(file):
    matList = []
    with open(file, 'r') as f:
        m = f.readlines()
        for line in m:
            l = line.split()
            if '[' in line:
                wavname = l[0]
                continue
            elif ']' in line:
                l.pop()
            matList.append([float(i) for i in l])
    return np.asarray(matList).T, wavname

def plotMFCC(matrix, wavname):
    plt.figure()
    plt.imshow(matrix)
    plt.show()
    #plt.savefig(name)

def main():
    parser = argparse.ArgumentParser(description = 'Plot MFCC')
    parser.add_argument('mfcc', help = 'Input single MFCC file')
    args = parser.parse_args()

    m, name = readMFCC(args.mfcc)
    plotMFCC(m, name)

if __name__ == '__main__':
    main()

