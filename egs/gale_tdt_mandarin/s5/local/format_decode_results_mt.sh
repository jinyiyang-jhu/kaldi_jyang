#!/bin/bash

# This script reformat the segment id of decoding result.

stage=-1
decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test

if [ $stage -le 0 ]; then
  echo "Filtering ASR outpu"
  for dset in tune eval; do
    datadir=gale_${dset}_mt_no_rnn
    for x in bc bn;do
      mkdir -p $datadir/$x
      #cp gale_${dset}_mt/$x/segments $datadir/$x/segments
      awk '{print $1}' $datadir/$x/segments > $datadir/$x/segments.id
      filter=$datadir/$x/segments.id
      score_dir=$decode_dir/scoring_mahsa_${dset}_${x}
      best_cer=`cut -d " " -f 14 $score_dir/best_cer | awk -F "/" '{print $NF}'`
      lmwt=`echo $best_cer | cut -d "_" -f2`
      wip=`echo $best_cer | cut -d "_" -f3`
      echo "Set is $dset, type is $x, lmwt is $lmwt, wip is $wip" > $datadir/$x/lmwt_wip
      cer_result=$decode_dir/scoring_kaldi/penalty_${wip}/$lmwt.chars.txt
      wer_result=$decode_dir/scoring_kaldi/penalty_${wip}/$lmwt.txt
      cat $cer_result | grep -f $filter > $datadir/$x/asr.chars.part.txt
      cat $wer_result | grep -f $filter > $datadir/$x/asr.words.part.txt
      cp $score_dir/test_filt.chars.txt  $datadir/$x/text.filt.chars.txt
    done
  done
echo "Filter ASR output done"
fi


exit 0
if [ $stage -le 1 ]; then
  for dset in tune eval; do
    datadir=gale_${dset}_mt
    for x in bc bn;do
      result_dir=asr_results_mt/${dset}/$x
      mkdir -p $result_dir
      for type in chars words; do
        asr_part=$datadir/$x/asr.$type.part.txt
        wav_list=$datadir/$x/wav.list
        all_segs=$datadir/$x/segments_mt_full
      awk 'NR==FNR{
        str=$2;
        for (i=3;i<=NF;++i) {
          str=str" "$i;
          }
        a[$1]=str;
        next;
      }
      {
        if ($2 in a){
          print $1" "a[$2];
        }
        else{
          print $1;
        }
      }' $asr_part $all_segs > $datadir/$x/asr.$type.full.sorted.txt

      done
      for wav in $(cat $datadir/$x/wav.list | xargs -n1 basename); do
        cat $datadir/$x/asr.chars.full.sorted.txt | grep $wav \
           > $result_dir/$wav.txt
      done
    done
  done
fi
