#/home/jyang/anaconda3/bin/python

import numpy as np
import re
import argparse


def read_monophone_post(post_file, num_phones):
    utt_dict = dict()
    post_frame = np.empty(int(num_phones))
    flag = None
    with open(post_file, 'r') as p:
        p_list = p.readlines()
        for p_line in p_list:
            flag = re.search('\[', p_line)
            if flag is None:
                p_line = p_line.replace(']', '')
               # p_line = p_line.split()
               # p_float = [float (i) for i in p_line]
                post_frame = np.asarray([float (i) for i in p_line.split()])
                if utt_dict[utt] is None:
                    utt_dict[utt] = np.array([post_frame])
                else:
                    utt_dict[utt] = np.concatenate((utt_dict[utt],[post_frame]))
            else:
                utt = p_line.split()[0]
                utt_dict[utt] = None
    return utt_dict

def main():
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('post')
    parser.add_argument('num_phones')
    args = parser.parse_args()

    y = read_monophone_post(args.post, args.num_phones)
    for k in y.keys():
        list_k = y[k].tolist()
        print (list_k)

if __name__ == '__main__':
    main()
else:
    raise ImportError('Can not be imported')


