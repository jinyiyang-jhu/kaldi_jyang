#!/usr/bin/python3

import numpy as np
from scipy.io.wavfile import write

filename='./noise_1000hz.wav'
A = .8
f = 1000
fRate = 16000
t = np.arange(0,20,1 / fRate)
phi = np.pi/4
x = A * np.cos(2 * np.pi * f * t + phi)

write(filename, fRate, x, dtype='int16')
