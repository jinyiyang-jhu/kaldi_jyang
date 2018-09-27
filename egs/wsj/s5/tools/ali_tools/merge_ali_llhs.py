
'''Merge per frame llhs into phones'''

import argparse
import numpy

def read_llhs(fid):
    dict_llhs = {}
    with open(fid, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            utt = tokens.pop(0)
            tokens.pop(0)
            tokens.pop(-1)
            dict_llhs[utt] = np.array(tokens)
    return dict_llhs

def read_phone_map(fid):
    dict_map = {}
    with open(fid, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            dict_map[tokens[0]] = dict_map[tokens[1]]
    return dict_map

def read_ali_phones(fid):
    dict_phones

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('per_frame_llhs', help='File with per frame llhs')
    parser.add_argument('ali_phones', help='File with aligned phones and frame counts')
    parser.add_argument('phone_map', help='File with root phone to phone id map')
    parser.add_argument('output', help='File to write per phone llhs')
    args = parser.parse_args()

    per_frame_llhs = args.per_frame_llhs
    ali_phones = args.ali_phones

    per_phone_llhs = args.output
     



if __name__ == '__main__':
    main()
