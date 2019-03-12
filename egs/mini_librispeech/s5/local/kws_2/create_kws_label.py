#!/usr/bin/env python3

# This script generates the score and label files for keywords, which will
# be used for computing the precison and recall. For each keyword, there will
# be two file generated: keyword_name_score.txt and keyword_name_labels.txt


from __future__ import print_function
import sys, argparse, os

def GetArgs():
    parser = argparse.ArgumentParser(description="Generate the score and"
        "label files for each keyword. "
        "Usage: local/kws_2/create_kws_label.py <keywords-file> "
        "<align_ctm_file> <lattice_post_ctm_file> "
        "E.g., local/kws_2/create_kws_label.py [options ...] keywords.list "
        "ali_post.txt lattice_post.txt",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--time-tolerance", type=float, dest="time_tolerance",
        help="Time gap tolerance between the location in align and lattice")
    parser.add_argument("keyword_file", 
        help="List of keywords, each line is a keyword")
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

def CheckArgs(args):
    if args.time_tolerance < 0:
        raise Exception("--time-tolerance can not be negative !")
    return args

def read_kws(keyword_file):
    keywords_list = []
    with open(keyword_file, 'r') as fid:
        for line in fid.readlines():
            keywords_list.append(line.rstrip())

def main():
    args = GetArgs()
    keyword_list = open(args.keyword_file)
    align_file = open(args.align_post_file)
    lattice_file = open(args.lattice_post_file)
    


