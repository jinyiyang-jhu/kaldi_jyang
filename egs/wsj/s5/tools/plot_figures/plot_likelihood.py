#!/home/jyang/anaconda3/bin/python3.6

import argparse
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import numpy as np


def read_log_likeli(log_file):
    '''
    uttid [ log-frame1 log-frame2 ... ]
    log-frame could be from DNN, which is pseudo log, could be
    positive/negative

    '''
    uttDict = dict() 
    with open(log_file, 'r') as f:
        logs = f.readlines()
        num_of_utt = len(logs)
        for i in logs:
            l = i.split()
            utt_id = l.pop(0)
            l.pop(0)
            l.pop()
            uttDict[utt_id] = np.array([float(j) for j in l])
    return uttDict

def plot_log_likeli(uttDict, utt_id, fig):
    '''
    uttDict[uttid] = list[float(frame1-log) ... ]
    utt-id : x-th utt needed to be ploted, eg. 1, 2, ...

    '''
    plt.plot(uttDict[utt_id])
    plt.xlabel('Frame')
    plt.ylabel('Likelihood')
    #plt.ylim(-10, 10)
    plt.savefig(fig)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('log_likes',help = 'Input log likeli file')
    parser.add_argument('fig', help = 'fig name')
    parser.add_argument('fig_id', help = 'utt name to be plotted')
    args = parser.parse_args()

    likes = read_log_likeli(args.log_likes)
    plot_log_likeli(likes, args.fig_id, args.fig)


if __name__ == '__main__':
    main()
