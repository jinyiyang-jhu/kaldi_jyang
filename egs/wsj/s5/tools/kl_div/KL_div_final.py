#!/usr/bin/python3
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import argparse
import numpy as np
from read_files import read_kaldi_post
from scipy.stats import entropy
from scipy.signal import medfilt


####################### Function #######################################

## Compute KL-divgence between posteriors from nnet/lat/align
## Optional: Smooth KL-div with square/median filter
## Optional: Smooth KL-div with context window on denominator(Lukas et.al)

################################ #######################################


def check_and_compute\
    (p_dict,  q_dict, win, symmetric, filt, kernel_size, threshold):
    kl=dict()
    kl_p2q=dict()
    kl_q2p=dict()

    for p_key in p_dict.keys():
        p = p_dict[p_key]
        if p_key in q_dict.keys():
            q = q_dict[p_key]
            if p.shape[0] != q.shape[0]:
                print ('Error: for utt ' + p_key + 'X has ' \
                        + str(p.shape[0]) +' frames; Y has ' \
                        + str(q.shape[0]) + ' frames')
                sys.exit(1)
            else:
                if symmetric == 'True':
                   kl_p2q[p_key] = kl_compute(p, q, p.shape[0], win, threshold)
                   kl_q2p[p_key] = kl_compute(q, p, p.shape[0], win, threshold)
                   kl[p_key] = 1/2 * (np.array(kl_p2q.get(p_key)) \
                               + np.array(kl_q2p.get(p_key)))
                else:
                   kl[p_key] = kl_compute(p, q, p.shape[0], win, threshold)
                if filt == "no_filt":
                   continue
                if filt == "median":
                   kl[p_key]= medfilt(kl[p_key], kernel_size)
                if filt == "square":
                   avrg_filt = np.ones(kernel_size)
                   kl[p_key] = np.convolve(kl[p_key], avrg_filt, 'same')
                   kl[p_key] = kl[p_key] / kernel_size
        else:
            print ('Error: utterance [' + p_key + '] is not in Q post file')
            sys.exit(1)
    return kl



def kl_compute(p, q, num_frames, win, threshold):
    KL_vec=[]
    for frame in range (num_frames):
        if check_skip_phones(skip_phones, p[frame], q[frame], threshold):
            print ('Skip frame ' + str(frame) )
            continue
        if frame < win or frame >= num_frames - win:
            KL_frame = entropy(p[frame], q[frame])
        else:
            KL_num_sum = 0.0  # Numerator
            KL_den_sum = 0.0  # Denominator
            for splice in range(frame - win, frame + win + 1):
                (KL_num, KL_den) = kl_div_smooth(p[frame], q[splice])
                KL_num_sum += KL_num
                KL_den_sum += KL_den
            KL_frame = KL_num_sum / KL_den_sum
        KL_vec.append(KL_frame)
    return KL_vec


def check_skip_phones(skip_phones, x , y, threshold):
    xSum = 0
    ySum = 0
    skip = 0
    for i in skip_phones:
        xSum += x[int(i)-1]
        ySum += y[int(i)-1]
    if xSum >= threshold or ySum >= threshold:
        print ('Xsum is ' + str(xSum) + ' Ysum is ' + str(ySum))
        skip = 1
    return skip


def kl_div_smooth(pk, qk):
    pk_max_phone_prob = np.amax(pk)
    #pk_max_phone_id = np.where (pk == pk_max_phone_prob)
    pk_max_phone_id = np.argmax(pk)
    qk_weight_prob = qk[pk_max_phone_id]
    numerator = qk_weight_prob * entropy(pk,qk)
    denominator = qk_weight_prob
    return (numerator, denominator)



def main():
    parser = argparse.ArgumentParser\
    (description='Compute KL divergence between two posteriors')
    parser.add_argument\
    ('--post-type', nargs = '+', help='list of lat/nnet, no quotes')
    parser.add_argument\
    ('--input-X', help='phone post file\n')
    parser.add_argument\
    ('--input-Y', help='phone post file\n')
    parser.add_argument\
    ('--output-kl', help='output: KL file\n')
    parser.add_argument\
    ('--map-phone-to-pdf', help='phone-to-pdf map file\n')
    parser.add_argument\
    ('--filt-type', help='no_filt or median or square win\n', type = str)
    parser.add_argument\
    ('--filt-win-len', help='kernel_size\n', type = int)
    parser.add_argument\
    ('--context-win-len', help='for computing KL\n', type = int)
    parser.add_argument\
    ('--threshold', help='for skip frames with larger sum of SIL SPN NSN\n')
    args=parser.parse_args()

########################################################################

### Read arguments

########################################################################

    # symmetric KL divergence
    symmetric = 'True'
    # Filter type: square win (colv) or median
    filt_type = "square"
    # Filter win size length (left + right)
    kernel_size = 31
    # context win for smoothing KL-div ( win on denominator posts)
    win = 0
    # Don't compute KL-div on these phones: SIL(1st) SPN(2nd) NSN(3rd).
    # Check map-phone-int*.map for phone-ids
    # If sum of these phones is larger than threshold, skip this frame.
    global skip_phones
    skip_phones = {'1', '2', '3'}
    threshold = 0.30
    filt_type = str(args.filt_type)
    kernel_size = int(args.filt_win_len)
    win = int(args.context_win_len)
    threshold = float(args.threshold)

    kl = {}
    input_files = [args.input_X, args.input_Y]
    f_list = []
    post_type = args.post_type
    for i in range(len(input_files)):
        f = input_files[i]
        p_type = post_type[i]
        if p_type == 'nnet':
            p = read_kaldi_post.readKaldiNnetPhonePost\
                (f, merge_NSN = 'True', merge_SPN = None, add_epsilon = 'True')
        else:
            if p_type == 'lat':
                p = read_kaldi_post.readKaldiLatPhonePost\
                (f, args.map_phone_to_pdf, add_epsilon = 'True')
            else:
                print ('Error: wrong format of post', p_type)
                print ('Should be nnet or lat')
                sys.exit(1)
        f_list.append(p)

    kl = check_and_compute\
              (f_list[0], f_list[1], win, symmetric, filt_type, \
              kernel_size, threshold)
    kl_dir = os.path.dirname(args.output_kl)
    if not os.path.exists(kl_dir):
            os.mkdir(kl_dir)

    with open(args.output_kl,'w') as KL:
        for utt in kl.keys():
            utt_value= ' '.join([str(i) for i in kl[utt].tolist()])
            KL.write(utt + ' ' + utt_value + '\n')

if __name__=='__main__':
    main()
else:
    raise ImportError('This script cannot be imported')



