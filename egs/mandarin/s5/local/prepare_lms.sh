#!/bin/bash

if [ $# != 3 ]; then
  echo "Usage: <gale-tdt-lm-src-dir> <giga-lm-src-dir> <lm-dir>"
  echo "E.g. $0 <data/local/train> <data/local/gigaword_chinese> <data/local/lm>"
fi

local_text_dir=$1
extra_text_dir=$2
lm_dir=$3

if [ -z $local_text_dir/lm/srilm/*.gz ]; then
  echo "Training LM with train text"
  cut -d " " -f1 $local_text_dir/text > $local_text_dir/lm/text
  local/train_lms.sh $local_text_dir/lm $local_text_dir/lm
fi

if [ -z $extra_text_dir/lm/srilm/*.gz ]; then
  echo "Training LM with extra text"
  local/train_lms.sh $extra_text_dir $extra_text_dir/lm
fi


echo "LM interpolation......"
if [ -z $lm_dir/best-mix.ppl ]; then
  for d in $local_text_dir/lm $extra_text_dir/lm ; do
    ngram -debug 2 -order 3 -unk -lm $d/3gram-mincount/lm_unpruned.gz \
      -ppl $local_text_dir/lm/srilm/heldout > $d/3gram-mincount/lm.ppl ;
  done
  compute-best-mix $local_text_dir/lm/3gram-mincount/lm.ppl \
    $extra_text_dir/lm/3gram-mincount/lm.ppl > $lm_dir/best-mix.ppl
fi

echo "local:extra=0.8:0.2" > $lm_dir/mix.pair

ngram -order 3 -unk \
  -lm $local_text_dir/lm/3gram-mincount/lm_unpruned.gz -lambda 0.8 \
  -mix-lm $extra_text_dir/lm/3gram-mincount/lm_unpruned.gz \
  -write-lm $lm_dir/3gram_mincount_ixed_lm.gz

ngram -debug 2 -order 3 -unk -lm $lm_dir/3gram_mincount_ixed_lm.gz \
  -ppl $local_text_dir/lm/srilm/heldout > $lm_dir/lm.ppl
