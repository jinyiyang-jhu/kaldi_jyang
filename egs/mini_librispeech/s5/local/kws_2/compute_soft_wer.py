#!/usr/bin/env python3

# This file create the score and labels files for compute the soft wer. The
# output format is like :
# word-id 
# score1 label2 (0 or 1)
# score2 label2

from __future__ import print_function
import sys, argparse, os

def get_args():
    parser = argparse.ArgumentParser(description="Generate the score and"
        "label files for each keyword. "
        "Usage: local/kws_2/create_kws_label.py <keywords-file> "
        "<align_ctm_file> <lattice_post_ctm_file> "
        "E.g., local/kws_2/create_kws_label.py [options ...] keywords.list "
        "ali_post.txt lattice_post.txt",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--time-tolerance", type=float, dest="time_tolerance",
        help="Time gap tolerance between the location in align and lattice")
    parser.add_argument("align_post_file", 
        help="Ctm format alignments with posterior, with columns of the form "
        "<uttid> <start-frame> <num-frames> <posterior> <word> <phone1> "
        "<phone2> ...")
    parser.add_argument("lattice_post_file",
        help="Ctm format alignments with posterior, with columns of the form "
        "<uttid> <start-frame> <num-frames> <posterior> <word> <phone1> "
        "<phone2> ...")
    parser.add_argument("output_dir", 
    help="Directory to store the generated files, for each word there will be
    two ")
    sys.stderr.write(' '.join(sys.argv) + '\n')
    args = parser.parse_args()
    args = CheckArgs(args)
    return args


def compute_overlap(period1, period2):
    '''Compute the overlap percentage between two periods.
    Args:
    period1: list of [stime, etime], dtype=float
    period2: list of [stime, etime], dtype=float
    '''
    if (period2[1] - period1[0]) * (period1[1] - period2[0]) >= 0:
    # Overlap
        stime = max(period1[0], period2[0])
        etime = min(period1[1], period2[1])
        return (etime - stime) / (period1[1] - period1[0])
    else:
        return 0.

def create_word_map()
