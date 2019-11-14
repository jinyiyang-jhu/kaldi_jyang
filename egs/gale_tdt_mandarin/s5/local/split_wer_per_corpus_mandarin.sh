#!/bin/bash

# Report WER for reports and conversational
# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0

if [ $# -ne 2 ]; then
   echo "Arguments should be the <lang-dir> <decode-dir> see ../run.sh for example."
   exit 1;
fi

[ -f ./path.sh ] && . ./path.sh

set -o pipefail -e

#galeFolder=$(utils/make_absolute.sh $1)
langdir=$1
decode_dir=$2
symtab=$langdir/words.txt

min_lmwt=7
max_lmwt=20

#for dir in exp/*/*decode*; do
dir=$decode_dir
for type in $(ls -1 local/test.* | xargs -n1 basename); do
  rm -fr $dir/scoring_$type
  mkdir -p $dir/scoring_$type/log
  for x in $dir/scoring_kaldi/test_filt.chars.txt $dir/scoring_kaldi/test_filt.txt; do
    cat $x | grep -f local/$type > $dir/scoring_$type/$(basename $x)
  done
 for penalty in 0.0 0.5 1.0; do
   mkdir -p $dir/scoring_$type/penalty_${penalty}
   #cat $dir/scoring_kaldi/penalty_${penalty}/LMWT.txt | grep -f local/$type \
   # > $dir/scoring_${type}/penalty_${penalty}/LMWT.txt
   #cat $dir/scoring_kaldi/penalty_${penalty}/LMWT.char.txt | grep -f local/$type \
   # > $dir/scoring_${type}/penalty_${penalty}/LMWT.char.txt

  utils/run.pl LMWT=$min_lmwt:$max_lmwt $dir/scoring_$type/penalty_${penalty}/log/score.LMWT.log \
     cat $dir/scoring_kaldi/penalty_${penalty}/LMWT.txt \| grep -f local/$type \| \
     sed 's:\<UNK\>::g' \| \
     compute-wer --text --mode=present \
     ark:$dir/scoring_${type}/test_filt.txt  ark,p:- ">&" $dir/wer_${type}_LMWT_${penalty}
  utils/run.pl LMWT=$min_lmwt:$max_lmwt $dir/scoring_$type/penalty_${penalty}/log/score.cer.LMWT.log \
     cat $dir/scoring_kaldi/penalty_${penalty}/LMWT.chars.txt \| grep -f local/$type \| \
     sed 's:\<UNK\>::g' \| \
     compute-wer --text --mode=present \
     ark:$dir/scoring_${type}/test_filt.chars.txt  ark,p:- ">&" $dir/cer_${type}_LMWT_${penalty}
  done
done
#done

for type in $(ls -1 local/test.* | xargs -n1 basename); do
  echo -e "\n# WER $type"
  #for x in exp/*/*decode*; do
  x=$dir
    grep WER $x/wer_${type}_* | utils/best_wer.sh;
  #done | sort -n -k2
done

for type in $(ls -1 local/test.* | xargs -n1 basename); do
  echo -e "\n# CER $type"
  #for x in exp/*/*decode*; do
  x=$dir
    grep WER $x/cer_${type}_* | utils/best_wer.sh;
  #done | sort -n -k2
done



