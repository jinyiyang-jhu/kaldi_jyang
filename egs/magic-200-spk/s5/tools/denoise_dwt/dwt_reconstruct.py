#!/home/jyang/anaconda3/bin/python3.6

import pywt
import sys
import numpy as np
from scipy.io import wavfile
import argparse
import math

def dwt_reconstruction(x, L, wname, ignore, rec_with):
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

#def compute_SNR(sig, noise):
#    sig_power = np.sum(np.square(sig, dtype='int64'), dtype='int64')
#    noise_power = np.sum(np.square(noise, dtype='int64'), dtype='int64')
#    snr = 10 * math.log10(sig_power/noise_power)
#    return float(snr)



def main():
    parser = argparse.ArgumentParser(description=
    '''Adding noise from a noise file to a list of audios''')
  #  parser.add_argument('--clean', help='clean audio',required=True)
    parser.add_argument('--nfile', help='noised audio',required=True)
    parser.add_argument('--dnfile', help='denoised file',required=True)
    parser.add_argument('--level', type=int, default=5, help='DWT level')
    parser.add_argument('--wav_name', type=str,default='db8', help='wvlet name')
    parser.add_argument('--ign_level', type=str, default='[30]', help='ignored detail level')
    parser.add_argument('--c_or_d', type=str, default='cd', help='cd:both coarse and detail; \'d\':details')
    parser.add_argument('--uttid', type=str, required=True,help='utterance id')
#    parser.add_argument('--only_snr', type=str, default='no', help='Only compute SNR')
    args = parser.parse_args()
  #  cRate, clean = wavfile.read(args.clean)
    nRate, noisy = wavfile.read(args.nfile)
    x_rec = dwt_reconstruction(noisy, args.level, args.wav_name, args.ign_level, args.c_or_d)
    #if  args.only_snr == 'no':
    wavfile.write(args.dnfile, nRate, x_rec)

  #  if clean.size != x_rec.size:
  #      x_rec = x_rec[:clean.size]
  #  rec_noise = clean - x_rec
  #  snr = compute_SNR(x_rec, rec_noise)
  #  print (args.uttid + ' SNR is ' + str(snr))




if __name__ == '__main__':
    main()
else:
    raise ImportError('This script cannot be imported')
