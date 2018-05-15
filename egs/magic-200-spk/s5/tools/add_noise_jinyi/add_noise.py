#!/usr/bin/python3

from scipy.io import wavfile
import numpy as np
import argparse
import sys
import math
import subprocess
import io
import os


def add_noise(ifile, noiseFile, snr, pipe=True):
    nSmpRate, nwav = wavfile.read(noiseFile)
    if not pipe:
        iSmpRate, iwav = wavfile.read(ifile)
    else:
        tmp = io.BytesIO(sys.stdin.buffer.read())
        iSmpRate, iwav = wavfile.read(tmp)
        dtype = iwav.dtype

    if (iSmpRate != nSmpRate):
        sys.exit('Audio file smprate ' + str(iSmpRate) + ' not equal to noise')
    sig_len = len(iwav)
    if (sig_len > len(nwav)):
        sys.exit('Signal longer than noise, exiting...')
    else:
        noise_cut = nwav[:sig_len]
        sig_power = np.sum(np.square(iwav))
        noise_power = np.sum(np.square(noise_cut))
        B = math.pow(10, float(snr)/10)
        K_square = sig_power/(noise_power * B)
        K = math.sqrt(K_square)
        noisy = np.add(iwav, K * noise_cut)
        #if not os.path.exists(os.path.dirname(ofile)):
        #    os.makedirs(os.path.dirname(ofile))
        tmp = io.BytesIO()
        wavfile.write(tmp, iSmpRate, noisy.astype(dtype))
        sys.stdout.buffer.write(tmp.getvalue())

def main():
    parser = argparse.ArgumentParser(description=
    '''Adding noise from a noise file to a list of audios''')
    parser.add_argument('i', help='input audio file')
    parser.add_argument('--ipipe', default=True, help='input pipe or not')
    parser.add_argument('--n', help='noise file')
    parser.add_argument('--snr')
    args = parser.parse_args()


    add_noise(args.i, args.n, float(args.snr), pipe=args.ipipe)

if __name__ == '__main__':
    main()

