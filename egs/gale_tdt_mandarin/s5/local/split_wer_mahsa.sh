#!/bin/bash

# Report WER for reports and conversational
# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0


[ -f ./path.sh ] && . ./path.sh

set -o pipefail -e
stage=-1
decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test_rnnlm_1a_rescore

min_lmwt=7
max_lmwt=20

if [ $stage -le 0 ]; then
  for dset in tune eval; do
    datadir=data/gale_${dset}_mahsa_blank_ref
    for x in bc bn;do
      score_dir=$decode_dir/scoring_mahsa_${dset}_${x}
      mkdir -p $score_dir
      wav_list=$datadir/$x/wav.list
      for ref in $decode_dir/scoring_kaldi/test_filt.chars.txt $decode_dir/scoring_kaldi/test_filt.txt; do
        cat $ref | grep -f $wav_list > $score_dir/$(basename $ref)
      done
      for penalty in 0.0 0.5 1.0; do
        mkdir -p $score_dir/penalty_${penalty}
       utils/run.pl LMWT=$min_lmwt:$max_lmwt $score_dir/penalty_${penalty}/log/score.cer.LMWT.log \
          cat $decode_dir/scoring_kaldi/penalty_${penalty}/LMWT.chars.txt \| grep -f $wav_list\| \
          sed 's:\<UNK\>::g' \| \
          compute-wer --text --mode=present \
          ark:$score_dir/test_filt.chars.txt  ark,p:- ">&" $score_dir/cer_LMWT_${penalty}
       utils/run.pl LMWT=$min_lmwt:$max_lmwt $score_dir/penalty_${penalty}/log/score.wer.LMWT.log \
          cat $decode_dir/scoring_kaldi/penalty_${penalty}/LMWT.txt \| grep -f $wav_list\| \
          sed 's:\<UNK\>::g' \| \
          compute-wer --text --mode=present \
          ark:$score_dir/test_filt.txt  ark,p:- ">&" $score_dir/wer_LMWT_${penalty}
      done
    grep WER $score_dir/wer_* | utils/best_wer.sh > $score_dir/best_wer
    grep WER $score_dir/cer_* | utils/best_wer.sh > $score_dir/best_cer
    done
  done
fi
