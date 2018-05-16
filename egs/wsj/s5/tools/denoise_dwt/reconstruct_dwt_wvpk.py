#!/home/jyang/anaconda3/bin/python3.6

import pywt
import sys
import numpy as np
from scipy.io import wavfile
import argparse
import math
import subprocess
import io

def dwt_reconstruction(x, L, wname, ignore, rec_with):
    '''
    x: np.array(), signal
    L: int16, DWT/wvpk level
    wname: str, wavelet name
    ignore: list, within which the corresponding bands are moved
    rec_with: str, c -> approx only; d -> details only; cd -> both
    '''
    approx = x
    details = []
    ignore = eval(ignore)
    for i in range(L):
        approx, d = pywt.dwt(approx, wname)
        details.append(d)
    if rec_with == 'd':
        y_approx = np.zeros(approx.size)
    elif (rec_with == 'c') or (rec_with == 'cd'):
        y_approx = approx
    else:
        sys.exit('Unknow reconstruct type: c , d, or cd ?')
    for j in reversed(range(L)):
        if y_approx.size != len(details[j]):
            y_approx = y_approx[:len(details[j])]
        np_details = np.array(details[j])
        if rec_with == 'c':
            np_details = np.zeros(len(details[j]))
        elif j+1 in ignore:
            np_details = np.zeros(len(details[j]))
        y_approx = pywt.idwt(y_approx, np_details, wname)
    x_rec = y_approx

    return np.array(x_rec, dtype='int16')

def wvpk_reconstruction(x, L, wname, ignore):
    '''
    Divide bands into 2^L, higher index(e.g., 8>1), higher frequency.
    wvpk indexes from 0, so band indexes are from 0 ~ L-1
    ignore: list, indexing i + 1 = index in bands. E.g., fs = 16k,
    ignore[3] means ignore band 4 in picture, freq ranges from 
    8000 / (2^3) * (3) - 8000 / (2^3) * (3+1) = 3000 - 4000
    '''
    oriwp = pywt.WaveletPacket(data = x, wavelet=wname, mode='sym', maxlevel=L)
    ignore = eval(ignore)
    nodes = [n.path for n in oriwp.get_level(L, 'freq')]
    for i in ignore:
        oriwp[nodes[i]].data = np.zeros(len(oriwp[nodes[i]].data))
    return oriwp.reconstruct(False).astype(np.int16)

def main():
    parser = argparse.ArgumentParser(description=
    '''Adding noise from a noise file to a list of audios''')
  #  parser.add_argument('--clean', help='clean audio',required=True)
    parser.add_argument('--nfile', help='noised audio',required=True)
    parser.add_argument('--dnfile', help='denoised file',required=True)
    parser.add_argument('--level', type=int, default=5, help='DWT level')
    parser.add_argument('--wav_name', type=str,default='db8', help='wvlet name')
    parser.add_argument('--dwt_or_wvpk', type=str, default='wvpk')
    parser.add_argument('--ign', type=str, default='[30]', help='ignored detail level')
    parser.add_argument('--c_or_d', type=str, default='cd', help='cd:both coarse and detail; \'d\':details')
    parser.add_argument('--uttid', type=str, required=True,help='utterance id')
    args = parser.parse_args()
  #  cRate, clean = wavfile.read(args.clean)
    if '|' in args.nfile: # Pipe out
        output = subprocess.check_output(args.nfile[:-1], shell=True)
        f = io.BytesIO(output)
        nRate, noisy = wavfile.read(f)
    else:
        nRate, noisy = wavfile.read(args.nfile)

    if args.dwt_or_wvpk == 'dwt':
        x_rec = dwt_reconstruction(noisy, args.level, args.wav_name, args.ign, args.c_or_d)
    elif args.dwt_or_wvpk == 'wvpk':
        x_rec = wvpk_reconstruction(noisy, args.level, args.wav_name, args.ign)

    wavfile.write(args.dnfile, nRate, x_rec)




if __name__ == '__main__':
    main()
#else:
#    raise ImportError('This script cannot be imported')
