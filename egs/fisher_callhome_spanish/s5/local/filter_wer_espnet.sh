#!/bin/bash

# This script reformat the segment id of decoding result.

stage=-1
kaldi_data_dir=/export/b07/jyang/kaldi-jyang/kaldi/egs/fisher_callhome_spanish/s5/data
kaldi_mdl_dir=/export/b07/jyang/kaldi-jyang/kaldi/egs/fisher_callhome_spanish/s5/exp/chain/multipsplice_tdnn
espnet_data_dir=/export/b02/jyang/espnet/egs/fisher_callhome_spanish/asr1b/data
espnet_mdl_dir=exp/train_sp.es_lc.rm_pytorch_train_bpe1000
test_sets="callhome_dev callhome_test dev dev2 test"
word_ins_penalty=0.0,0.5,1.0
min_lmwt=7
max_lmwt=17
. path.sh
. cmd.sh

cmd=run.pl
if [ $stage -le 0 ]; then
  echo "Filtering ASR output"
  for dset in $test_sets; do
    sort $espnet_data_dir/${dset}.es/utt2spk $kaldi_data_dir/$dset/utt2spk | \
      uniq -d | awk '{print $1}' > $kaldi_data_dir/$dset/overlap.uttid
    cp $kaldi_data_dir/$dset/overlap.uttid $espnet_data_dir/${dset}.es/overlap.uttid

		filter=$kaldi_data_dir/$dset/overlap.uttid
		kaldi_score_dir=$kaldi_mdl_dir/decode_fsp_train_${dset}_rnn_lstm_tdnn_1b_rescore/scoring_kaldi
		filt_kaldi_score_dir=$kaldi_score_dir/espnet_filtered_score
		mkdir -p $filt_kaldi_score_dir
		cat $kaldi_score_dir/test_filt.txt | grep -f $filter > $filt_kaldi_score_dir/test_filt.txt
    for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
      mkdir -p $filt_kaldi_score_dir/penalty_${wip}/log
      for lmwt in $(seq $min_lmwt $max_lmwt); do
        hyp_full=$kaldi_score_dir/penalty_${wip}/$lmwt.txt
        cat $hyp_full | grep -f $filter > $filt_kaldi_score_dir/penalty_${wip}/$lmwt.txt
      done
      $cmd LMWT=$min_lmwt:$max_lmwt $filt_kaldi_score_dir/penalty_$wip/log/score.LMWT.log \
        cat $filt_kaldi_score_dir/penalty_${wip}/LMWT.txt \| \
        compute-wer --text --mode=present \
        ark:$filt_kaldi_score_dir/test_filt.txt ark,p:- ">&" $filt_kaldi_score_dir/wer_LMWT_${wip} || exit 1;
    done
    for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
      for lmwt in $(seq $min_lmwt $max_lmwt); do
        grep WER $filt_kaldi_score_dir/wer_${lmwt}_${wip} /dev/null
      done
    done | utils/best_wer.sh >& $filt_kaldi_score_dir/best_wer
    best_wer_file=$(awk '{print $NF}' $filt_kaldi_score_dir/best_wer)
    best_wip=$(echo $best_wer_file | awk -F_ '{print $NF}')
    best_lmwt=$(echo $best_wer_file | awk -F_ '{N=NF-1; print $N}')
  done
echo "Filter ASR output done"
fi


