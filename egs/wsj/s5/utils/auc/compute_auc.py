
import sys
import io
import argparse

def read_post_file(filename, chain_model=False):
  "Read the lattice arc posterior file."
  utt_infos = {}
  with open(filename, 'r', encoding='utf-8') as fid:
    for line in fid.readlines():
      uttid, word, time_post_info = read_post_line(line)
      if uttid not in utt_infos.keys(): # New utterance
        utt_infos[uttid] = {} # key:word, value:[time_post_info]
        utt_infos[uttid][word] = [time_post_info]
      elif word not in utt_infos[uttid].keys(): # New word in same utterance
        utt_infos[uttid][word] = [time_post_info]
      else: # Same word in same utterance
          utt_infos[uttid][word] = check_duplicates(utt_infos[uttid][word],
                                                    time_post_info, word)
  return utt_infos

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

def compute_overlap(period1, period2, current_word):
    '''Compute the overlap percentage between two time periods.
    Args:
    period1: list of [stime, etime], dtype=float
    period2: list of [stime, etime], dtype=float
    '''
    if (period2[1] - period1[0]) * (period1[1] - period2[0]) >= 0:
    # Overlap
        stime = max(period1[0], period2[0])
        etime = min(period1[1], period2[1])
        denom = period1[1] - period1[0]
        if denom > 0.:
            return (etime - stime) / (period1[1] - period1[0])
        else:
            sys.exit(f'Word {current_word} has bad time : {period1}')
    else:
        return 0.

def check_duplicates(stored, current, current_word):
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
        overlap = compute_overlap([token[0], token[1]], [current[0], current[1]], current_word)
        if overlap > 0.:
            if token[2] >= current[2]:
                overlap_flag = 0
                update_stored.append(token)
        else:
            update_stored.append(token)
    if overlap_flag == 1:
        update_stored.append(current)
    return update_stored

def detect(ref_words_info, hyp_words_info, uttid, score_fid, overlap_thres=.5):
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
        if compute_overlap(ref_period, hyp_period, hyp_word) >= overlap_thres:
            detect_flag = 1
            print(f'{uttid} {ref_word} {hyp_word} {hyp[2]}', file=score_fid)
    return detect_flag


def compute_search_results(uttid, dict_ref, dict_hyp, score_fid, overlap_thres=.5):
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
                                     uttid=uttid, score_fid=score_fid,
                                     overlap_thres=overlap_thres)
            if detect_flag == 0:
                print(f'{uttid} {refs[0]} <eps> -1.', file=score_fid)

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('ref_post', help='Reference align posterior, format is like:\
    <Utt-id> <start-time> <duration> <posterior> <word> <phone1-id> <phone2-id> ...')
  parser.add_argument('hyp_post', help='Decoded lattice posterior. Same format as "ref_post"')
  parser.add_argument('score_file', help='Output file to store the scores.')
  parser.add_argument('--chain_model', action='store_true', default=False,
    help='True if lattice is from chain model, then time frames will be multiplied by 3.')
  args = parser.parse_args()
  chain_model = args.chain_model
  ref_post_infos = read_post_file(args.ref_post)
  hyp_post_infos = read_post_file(args.hyp_post)
  score_fid = open(args.score_file, 'w', encoding='utf-8')

  # Check if reference and hypothesisi has same number of utterances.
  ref_uttid_num = len(ref_post_infos.keys())
  hyp_uttid_num = len(hyp_post_infos.keys())
  if (ref_uttid_num != hyp_uttid_num):
    print(f'Reference posterior file has {ref_uttid_num} utterances, but \
    hypothesis posterior file has {hyp_uttid_num} utterances !', file=sys.stderr)

  # Begin to compute auc score for each utterance
  for uttid in ref_post_infos.keys():
    if uttid in hyp_post_infos.keys():
      ref_post_info = ref_post_infos[uttid]
      hyp_post_info = hyp_post_infos[uttid]
      compute_search_results(uttid, ref_post_infos[uttid], hyp_post_infos[uttid], 
                              score_fid)
    else:
      print(f'Utterance {uttid} not in hypothesis posterior file, skipping it.',
      file=sys.stderr)
  score_fid.close()
