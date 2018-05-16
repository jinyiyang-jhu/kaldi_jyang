#!/usr/bin/python3

from tools.read_files.read_kaldi_feats import read_kaldi_MFCC_scp
import matplotlib.pyplot as plt

def plot_MFCC(filename, figname):
    '''
    Plot only 1 utterance.
    filename: scp file, should contain only 1 utt
    figname: str
    '''
    uDict = read_kaldi_MFCC_scp.readScp(filename)




