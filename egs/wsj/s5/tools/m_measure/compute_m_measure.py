#!/usr/bin/python3
import argparse
import numpy as np
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from read_files.read_kaldi_feats import read_kaldi_MFCC_stream
import subprocess
from scipy.spatial.distance import euclidean
from scipy.spatial.distance import cosine
from scipy.stats import entropy




def m_measure(T, feats, delta_t=10, method='kl'):
    m = 0.0
    for i in range (delta_t, T):
        p = feats[i - delta_t, :]
        q = feats[i, :]
        if method == 'kl':
            m = m + (entropy(p, q) + entropy(q, p))
        elif method == 'euc':
            m = m + euclidean(p, q)
        elif method == 'cos':
            m = m + cosine(p, q)
        else:
            sys.exit('Method should be euc or kl or cos .')
    return m/(T - delta_t)



def compute_distance(feats, method='euc', delta_t=list(range(10,81,5))):

    '''
    Compute distance between two vectors.
    uName: utt name (str)
    feats: numpy array, frame * dimension.
    method: str, kl or euc
    Return is np array, len(delta_t) * 1
    '''
    T = feats.shape[0]
    new_delta_t = list(filter(lambda x: x<T, delta_t))
    delta_t = new_delta_t

    m_vec = np.zeros((len(delta_t)))
    i = 0
    for d in delta_t:
        m_vec[i] = m_measure(T, feats, d, method)
        i = i + 1
    return m_vec


def main():
    parser = argparse.ArgumentParser(description='''Computing m-measure score
for input MFCC features''')

    parser.add_argument('--i', help = 'input file list, i.e., scp file')
    parser.add_argument('--o', help = 'output file name, i.e., m-measure.txt')
    parser.add_argument('--method', help='kl or euc or cos', type = str)
    if len(sys.argv) < 2:
        parser.print_usage()
        sys.exit(1)

    args = parser.parse_args()
   # os.makedirs(args.o, exist_ok = True)
    deltas = list(range(1, 5)) + list(range(10, 81, 5))
    m_vec = np.zeros((len(deltas)))
    uttDict = {}
    with open(args.i, 'r') as s:
        files = s.readlines()
        for i, j in enumerate(files): 
            output = subprocess.check_output\
            ("/export/b07/jyang/kaldi-jyang/kaldi/src/featbin/copy-feats scp:\"awk \'NR=={count}\' {f} |\" ark,t:-".format(count=i+1, f=args.i), shell=True)
            uttStr = output.decode('utf-8')
            utt, uttFeats = read_kaldi_MFCC_stream.readStream(uttStr)
            uttDict[utt] = compute_distance(uttFeats, args.method, deltas)

    with open(args.o, 'w') as out:
        for k in sorted(uttDict):
            m_values = ' '.join([str(i) for i in uttDict[k].tolist()])
            out.write(utt + ' ' + m_values + '\n')

if __name__ == '__main__':
    main()
else:
    print ('Importing as module')
    #raise ImportError('This script can not be imported')
