#!/usr/bin/python

import numpy as np

def compute_spectrum(signal, fs, stype='power', winlen=.025, shift=.01):
    window_size = int(winlen * fs)
    frame_rate = int(shift * fs)
    nframes = (len(signal) - window_size) // frame_rate + 1
    frames = []
    for i in range(nframes):
        frames.append(signal[i * frame_rate : i * frame_rate + window_size] *
        np.hamming(window_size))
    frames = np.asarray(frames)

    if stype == 'power':
        spec = np.abs(np.fft.rfft(frames, n=512, axis = -1)) ** 2
    elif stype == 'abs':
        spec = np.abs(np.fft.rfft(frames, n=512, axis = -1))

    return np.log(spec.T)
