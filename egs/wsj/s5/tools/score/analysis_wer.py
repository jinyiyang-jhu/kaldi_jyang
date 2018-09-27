#!/usr/bin/python3

from __future__ import print_function
import argparse
import numpy as np

parser = argparse.ArgumentParser(description="""
This script is used for analysing wer_one_vs_split_graph.txt, which is obtained
from Beijing Magic task, compring WER from general LM model with biased
utt-level LM. It computes detailed S/I/D for each utt in this file, and output
a summarized file.""")

parser.add_argument('wer_one_vs_split', type = str, help = "Filename")
parser.add_argument('one_per_utt', type = str, help = "Filename, which is from
                    decodedir/scoring_kaldi/wer_details/per_utt, for general LM")
parser.add_argument('split_per_utt', type = str, help = "Filename, similar like
                    above, for biased LM")
parser.add_argument('analysis', type = str, help = "Output file name, format is
                    like: utt-id one_wer per_wer relative_improv s i d")

args = parser.parse_args()

try:
    wer_file = open(args.wer_one_vs_split, 'r')
    one_detail_file = open(args.one_per_utt, 'r')
    split_detail_file = open(args.split_per_utt, 'r')
except:
    sys.exit("analysis_wer.py: error opening input files")

try:
    analysis_file = open(args.analysis, 'w')
except:
    sys.exit("analysis_wer.py: error opening {0} to write".format(args.analysis))


while True:
    line = wer_file.readline()
    if line != '':
       each_line = line.split()
       utt_id = each_line[0]
       one_wer = each_line[1]
       split_wer = each_line[2]
       if ()
    else:
        break
