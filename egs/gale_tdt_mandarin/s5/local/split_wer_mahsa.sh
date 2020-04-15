#!/bin/bash

# Apache 2.0


[ -f ./path.sh ] && . ./path.sh

set -o pipefail -e
stage=-1
#decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test
decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test
test_sets="gale_tune gale_eval"
#test_sets="dev"
data_affix="_mahsa_blank_ref"
#data_affix=""

min_lmwt=7
max_lmwt=22
if [ $stage -le 0 ]; then
  for dset in ${test_sets}; do
    datadir=data/${dset}${data_affix}
    for x in bc bn;do
      score_dir=$decode_dir/scoring${data_affix}_${dset}_${x}
      mkdir -p $score_dir
      wav_list=$datadir/$x/wav.list
      for ref in $decode_dir/scoring_kaldi/test_filt.chars.txt $decode_dir/scoring_kaldi/test_filt.txt; do
        cat $ref | grep -f $wav_list > $score_dir/$(basename $ref)
      done
      for penalty in 0.0 0.5 1.0; do
        mkdir -p $score_dir/penalty_${penalty}
       utils/run.pl LMWT=$min_lmwt:$max_lmwt $score_dir/penalty_${penalty}/log/cp.cer.LMWT.log \
          cat $decode_dir/scoring_kaldi/penalty_${penalty}/LMWT.chars.txt \| grep -f $wav_list\| \
          sed 's:\<UNK\>::g' ">&" $score_dir/penalty_${penalty}/LMWT.chars.txt
       utils/run.pl LMWT=$min_lmwt:$max_lmwt $score_dir/penalty_${penalty}/log/score.cer.LMWT.log \
          cat $score_dir/penalty_${penalty}/LMWT.chars.txt \| \
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
