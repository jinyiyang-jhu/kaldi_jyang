#!/bin/bash

# This script reformat the segment id of decoding result.

stage=-1
decode_dir=exp/chain_cleanup/tdnn_1d_sp/decode_eval_large_test_rnnlm_1a_rescore

if [ $stage -le 0 ]; then
  for dset in tune eval; do
    datadir=gale_${dset}_mt
    for x in bc bn;do
      wav_list=$datadir/$x/wav.list
      score_dir=$decode_dir/scoring_mahsa_${dset}_${x}
      best_cer=`cut -d " " -f 14 $score_dir/best_cer | awk -F "/" '{print $NF}'`
      lmwt=`echo $best_cer | cut -d "_" -f2`
      wip=`echo $best_cer | cut -d "_" -f3`
      echo "Set is $dset, type is $x, lmwt is $lmwt, wip is $wip" > $datadir/$x/lmwt_wip
      cer_result=$decode_dir/scoring_kaldi/penalty_${wip}/$lmwt.chars.txt
      wer_result=$decode_dir/scoring_kaldi/penalty_${wip}/$lmwt.txt
      cat $cer_result | grep -f $wav_list > $datadir/$x/asr.chars.part.txt
      cat $wer_result | grep -f $wav_list > $datadir/$x/asr.words.part.txt
    done
  done
fi

if [ $stage -le 1 ]; then
  for dset in tune eval; do
    datadir=gale_${dset}_mt
    for x in bc bn;do
      mkdir -p asr_results_mt/gale_${dset}/$x
      for type in chars words; do
        asr_part=$datadir/$x/asr.$type.part.txt
        wav_list=$datadir/$x/wav.list
        all_ids=$datadir/$x/mt.clean.info.txt
      awk 'NR==FNR{
        str=$2;
        for (i=3;i<=NF;++i) {
          str=str" "$i;
          }
        a[$1]=str;
        next;
      }
      {
        st=sprintf("%d",$3*1000);et=sprintf("%d",$4*1000);
        uttid=$1"_"st"_"et;
        if ($3 in a){
          print uttid" "a[$3];
        }
        else{
          print uttid;
        }
      }' $asr_part $all_ids > $datadir/$x/asr.$type.full.sorted.txt

      done
      for wav in $(cat $datadir/$x/wav.list | xargs -n1 basename); do
        cat $datadir/$x/asr.chars.full.sorted.txt | grep $wav \
           > asr_results/$datadir/$x/$wav.txt
      done
    done
  done
fi
