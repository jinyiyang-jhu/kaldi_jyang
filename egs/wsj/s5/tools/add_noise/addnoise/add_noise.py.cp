#!/usr/bin/python3

from scipy.io import wavfile
import numpy as np
import argparse
import sys
import math
import subprocess


def add_noise(iFile, oFile, noiseFile, snr):
    print ('Processing file ' + iFile)
    nSmpRate, noise = wavfile.read(noiseFile)
    iSmpRate, signal = wavfile.read(iFile)
    if (iSmpRate != nSmpRate):
        sys.exit('Audio file smprate ' + str(iSmpRate) + ' not equal to noise')
    sig_len = signal.size
    if (sig_len > noise.size):
        sys.exit('Signal longer than noise, exiting...')
    else:
        noise_cut = noise[:sig_len]
        sig_power = np.sum(np.square(signal, dtype='int64'), dtype='int64')
        noise_power = np.sum(np.square(noise_cut, dtype='int64'), dtype='int64')
        B = math.pow(10, snr/10)
        K_square = sig_power/(noise_power * B)
        K = math.sqrt(K_square)
        noisy = np.add(signal, K * noise_cut)
        noisy = np.around(noisy).astype(np.int16)
        wavfile.write(oFile, iSmpRate, noisy)

def main():
    parser = argparse.ArgumentParser(description=
    '''Adding noise from a noise file to a list of audios''')
    parser.add_argument('--i', help='input audio scp')
    parser.add_argument('--o', help='output agudio scp')
    parser.add_argument('--n', help='noise file')
    parser.add_argument('--snr', help='SNR')
    args = parser.parse_args()


    with open(args.o, 'r') as k:
        oL = k.readlines()

    with open(args.i, 'r') as f:
        iL = f.readlines()
        for j, iF in enumerate(iL):
            add_noise(iF.rstrip(), oL[j].rstrip(), args.n, float(args.snr))

if __name__ == '__main__':
    main()
else:
    raise ImportError('This script cannot be imported')

