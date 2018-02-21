import numpy as np
import sys
import os.path
import re



def readKaldiLatPhonePost(post_file, \
                          pdf_to_phone_map_file, \
                          add_epsilon = None):

    """
    Input post format:
    From Kaldi: lattice-to-phone-lattice

    uttid-1 [ dep_phone_id-1 post1 dep_phone_id-2 post2] ...  [] :per frame
    uttid-2 ...

    Input root_to_dep_phone_map format:
    root-id1 dep_phone_id-1 dep_phone_id-2 dep_phone_id-3 ...
    root-id2 dep_phone_id-5 dep_phone_id-10 ...

    Output post
    dict[utt] = np.array[[frame_1], [frame_2], ...
    dict[utt].shape = num_frames * num_phones(per frame)

    * Add epsilon to each element for computing KL-divergence. Dft: True

    """


    uttDict = dict()
    mapDict = dict()
    # add_epsilon = 'True'
    epsilon = 10 ** (-10)

    with open(pdf_to_phone_map_file, 'r') as f:
        m = f.readlines()
        num_of_phones = len(m)
        for i in m:
            l = i.split()
            phone = l.pop(0)
            for j in l:
                mapDict[int(j)] = int(phone)


    with open(post_file,'r') as pf:
        p_all = pf.readlines()
        for p_utt in p_all:                      # per utterance
            p_utt = p_utt.replace("]","")
            p_frames = p_utt.split("[")
            uttid = str(p_frames.pop(0)).strip()
            for p_one_frame in p_frames:  # per frame
                p_np = np.zeros(num_of_phones)
                check_phone_dict = dict()
                p = p_one_frame.split()
                for j in range(0, len(p), 2):
                    pdf = int(p[j])
                    post = float(p[j + 1])
                    if mapDict[pdf] in check_phone_dict:
                        p_np[mapDict[pdf] - 1] += post
                    else:
                        p_np[mapDict[pdf] - 1] = post
                        check_phone_dict[mapDict[pdf]] = 1
                if uttid in uttDict:
                    uttDict[uttid]= np.append(uttDict[uttid], [p_np], axis =0)
                else:
                    uttDict[uttid]= [p_np]

            if add_epsilon is not None:
                uttDict[uttid] = uttDict[uttid] + epsilon

    return uttDict


def readKaldiNnetPhonePost(post_file, \
                          merge_NSN = None, \
                          merge_SPN = None, \
                          add_epsilon = None):

    """
    Input post file format:
    From nnet-am-compute | transform-nnet-posteriors |
    Uttid1 [
    frame1 posts
    frame2 posts
    ...
    frame_last posts ]

    merge_NSN:
    Neural network was trained with phoneme "NSN", if we want to ignore
    this phonems, accoring to the phone-to-pdf map, NSN is 3rd place, we
    merge NSN with SIL

    merge_SPN:
    SPN is phoneme for OOV, if we want to skip this phoneme, we merge it
    with SIL, SPN is 2nd place in the phone-to-pdf map.

    Output post:

    dict[utt] = np.array[[frame_1], [frame_2], ...
    dict[utt].shape = num_frames * num_phones(per frame)

    * Add epsilon to each element for computing KL-divergence. Dft: True

    """


    epsilon = 10 ** (-10)
    utt_dict = dict()
    utt = ''
    with open(post_file, 'r') as p:
         p_all = p.readlines()
         for p_l in p_all:
           # Flag: first line with only uttid and [
             f_b = None
           # Flag: last line with ]
             f_e = None
             f_b = re.search('\[', p_l)
             f_e = re.search('\]', p_l)
             p_l = p_l.rstrip('\n')
             post = p_l.split()
             if f_b is not None:
                 utt = str(post[0]).strip()
                 continue
             else:
                if merge_NSN is not None:
                    post[0] = float(post[0]) + float(post[2])
                    del post[2]
                if merge_SPN is not None:
                    post[0] = float(post[0]) + float(post[1])
                    del post[1]
                if f_e is not None:
                    post.pop()
                #post_np = np.array(post, dtype=float)
                if utt in utt_dict:
                    utt_dict[utt] = np.append(utt_dict[utt], [post], axis = 0)
                else:
                    #utt_dict[utt] = [post_np]
                    utt_dict[utt] = [post]

    if add_epsilon is not None:
        for k in utt_dict.keys():
            utt_dict[k] = utt_dict[k].astype(float) + epsilon
    return utt_dict

#def compare_epsilon(element):

#   if abs(element) < epsilon:
#        element = epsilon
#    return element
