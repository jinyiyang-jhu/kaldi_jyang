
import sys
import io
import argparse

def read_post_line(line, chain_model=False):
    '''Read a line of lattice posterior
    line (str): format is <uttid> <stframe> <duration> <prob> <word> <phone-ids>
    chain_model (bool): if true, <stframe> and <duration> are multiplied by 3.
    '''
    tokens = line.strip().split()
    if len(tokens) == 0:
        return None, None, None
    else:
        uttid = tokens[0]
        word = tokens[4]
        tokens = [float(i) for i in tokens[1:4]]
        tokens[1] = tokens[0] + tokens[1]
        if chain_model:
            tokens[0] *= 3
            tokens[1] *= 3
    return uttid, word, tokens

def compute_overlap(period1, period2):
    '''Compute the overlap percentage between two time periods.
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

def check_duplicates(stored, current):
    '''Before store the current word instance, check if there are alreay
    duplicating words within time overlap tolerance. If so, only keep the one
    with largest probability
    Args:
    stored: [[begin_frame, duration, probability], [...], ...]
    current: [begin_frame, duration, probability]
    '''
    overlap_flag = 1
    update_stored = []
    for i, token in enumerate(stored):
        overlap = compute_overlap([token[0], token[1]], [current[0], current[1]])
        if overlap > 0.:
            if token[2] >= current[2]:
                overlap_flag = 0
                update_stored.append(token)
        else:
            update_stored.append(token)
    if overlap_flag == 1:
        update_stored.append(current)
    return update_stored

def detect(ref_words_info, hyp_words_info, uttid, overlap_thres=.5):
    '''Search current reference word instance in all hypotheses instances.
    Args:
    ref_words_info: (ref_word: [begin_time1, duration1, probability1])
    hyp_words_info: {hyp_word: [[begin_time1, duration1, probability]1, ...]}
    overlap_thres: timing overlap threshold between two instances.
    Return:
    detect_flag: if no time mathching instances found, return 0; otherwise
    returns 1.
    '''
    ref_word, ref_info = ref_words_info[0], ref_words_info[1]
    hyp_word, hyp_instances = hyp_words_info[0], hyp_words_info[1]
    ref_period = [ref_info[0], ref_info[1]]
    label = None
    detect_flag = 0
    for hyp in hyp_instances:
        hyp_period = [hyp[0], hyp[1]]
        if compute_overlap(ref_period, hyp_period) >= overlap_thres:
            detect_flag = 1
            print(f'{uttid} {ref_word} {hyp_word} {hyp[2]}')
    return detect_flag


def compute_search_results(uttid, dict_ref, dict_hyp, overlap_thres=.5):
    '''Search all word instances in current utterance.
    uttid: current utterance id
    dict_ref: {ref_word: [[begin_time1, duration1, probability1], ...]}
    dict_hyp: {ref_word: [[begin_time1, duration1, probability1], ...]}
    result_fid:
    '''
    ref_word_counts = {}
    search_results = {}
    for refs in dict_ref.items(): # refs: (word, [[bt1, et1, prob1], [bt2, et2, prob2], ...])
        for ref_instance in refs[1]:
            ref_item = (refs[0], ref_instance)
            detect_flag = 0
            for hyp in dict_hyp.items():
                detect_flag += detect(ref_words_info=ref_item, hyp_words_info=hyp,
                                     uttid=uttid, overlap_thres=overlap_thres)
            if detect_flag == 0:
                print(f'{uttid} {refs[0]} <eps> -1.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ref_post', help='Reference align posterior')
    parser.add_argument('hyp_post', help='Decoded lattice posterior')
    parser.add_argument('--chain_model', action='store_true', default=False,
        help='True if lattice is from chain model, then time frames will be multiplied by 3')
    args = parser.parse_args()
    chain_model = args.chain_model
    ref_fid = open(args.ref_post, 'r', encoding='utf-8')
    hyp_fid = open(args.hyp_post, 'r', encoding='utf-8')
    ref_line = ref_fid.readline()
    ref_uttid_previous, ref_word, ref_info = read_post_line(ref_line)
    hyp_line = hyp_fid.readline()
    hyp_uttid_previous, hyp_word, hyp_info = read_post_line(hyp_line, chain_model=chain_model)
    ref_dict = {}
    hyp_dict = {}
    ref_dict[ref_word] = [ref_info]
    hyp_dict[hyp_word] = [hyp_info]
    ref_eos = False
    hyp_eos = False
    while (ref_line or hyp_line):
        if (ref_eos and hyp_eos):
            if ref_uttid_previous != hyp_uttid_previous:
                sys.exit(f'Reference and hypothesis utterance id order different,\
                ref: {ref_uttid} hyp: {hyp_uttid}')
            else:
                compute_search_results(ref_uttid_previous, ref_dict, hyp_dict)
                ref_dict = {}
                hyp_dict = {}
                ref_dict[ref_word] = [ref_info]
                hyp_dict[hyp_word] = [hyp_info]
                ref_eos = False
                hyp_eos = False
                ref_uttid_previous = ref_uttid
                hyp_uttid_previous = hyp_uttid
        elif not ref_eos:
            ref_line = ref_fid.readline()
            ref_uttid, ref_word, ref_info = read_post_line(ref_line)
            if ref_uttid != ref_uttid_previous:
                ref_eos = True
            elif ref_word in ref_dict.keys():
                ref_dict[ref_word] = check_duplicates(ref_dict[ref_word], ref_info)
            else:
                ref_dict[ref_word] = [ref_info]
        elif not hyp_eos:
            hyp_line = hyp_fid.readline()
            hyp_uttid, hyp_word, hyp_info = read_post_line(hyp_line, chain_model=chain_model)
            if hyp_uttid != hyp_uttid_previous:
                hyp_eos = True
            elif hyp_word in hyp_dict.keys():
                hyp_dict[hyp_word] = check_duplicates(hyp_dict[hyp_word], hyp_info)
            else:
                hyp_dict[hyp_word] = [hyp_info]
    compute_search_results(ref_uttid_previous, ref_dict, hyp_dict)
    ref_fid.close()
    hyp_fid.close()
