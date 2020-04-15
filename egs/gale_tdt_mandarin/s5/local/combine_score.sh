#!/bin/bash

decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test
test_sets="mahsa_blank_ref_gale_eval_bn mahsa_blank_ref_gale_eval_bc"
tgt_dir=asr_cers_mahsa/eval_no_rnn

mkdir -p $tgt_dir
. path.sh
for d in ${test_sets}; do
  score_dir=$decode_dir/scoring_${d}
  best_cer=`cut -d " " -f 14 $score_dir/best_cer | awk -F "/" '{print $NF}'`
  lmwt=`echo $best_cer | cut -d "_" -f2`
  wip=`echo $best_cer | cut -d "_" -f3`
  cer_result=$score_dir/penalty_${wip}/$lmwt.chars.txt
  cp $cer_result $tgt_dir/$d.hyp.$d.$lmwt.$wip.txt
  cp $score_dir/test_filt.chars.txt $tgt_dir/$d.text.filt.chars.txt
done

cat $tgt_dir/*.hyp.*.*.*.txt > $tgt_dir/hyp.chars.txt
cat $tgt_dir/*.text.filt.chars.txt > $tgt_dir/ref.chars.txt

compute-wer --text --mode=present ark:$tgt_dir/ref.chars.txt ark:$tgt_dir/hyp.chars.txt > $tgt_dir/cer.txt
