#!/bin/bash

ngram_order=4

. path.sh
. utils/parse_options.sh

if [ $# != 4 ]; then
  echo "Usage: [--ngram-order ]<gale-tdt-lm-src-dir> <giga-lm-src-dir> <lm-dir> <dev-dir>"
  echo "E.g. $0 --ngram-order 4 data/local/train data/local/gigaword_chinese data/local/lm data/dev "
  exit 1
fi

local_text_dir=$1
extra_text_dir=$2
lm_dir=$3
heldout=$4/text

echo "Building $ngram_order gram LM"
[ ! -d $lm_dir ] && mkdir -p $lm_dir exit 1;
[ ! -d $local_text_dir/lm_${ngram_order}gram ] && mkdir -p $local_text_dir/lm_${ngram_order}gram && exit 1
[ ! -d $extra_text_dir/lm_${ngram_order}gram ] && mkdir -p $extra_text_dir/lm_${ngram_order}gram && exit 1

if [ ! -f $local_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz ]; then
  echo "Training LM with train text"
  [ ! -f $local_text_dir/text ] && echo "No $local_text_dir/text" && exit 1;
 # cut -d " " -f1- $local_text_dir/text > $local_text_dir/lm_${ngram_order}gram/text || exit 1
	awk '{i=$2;for (n=3;n<=NF;++n){i=i" "$n;}print i}' $local_text_dir/text > $local_text_dir/lm_${ngram_order}gram/text
  local/train_lms.sh --ngram-order $ngram_order \
    $local_text_dir/lm_${ngram_order}gram $local_text_dir/lm_${ngram_order}gram
fi

if [ ! -f $extra_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz ]; then
  echo "Training LM with extra text"
  [ ! -f $extra_text_dir/text ] && echo "No $extra_text_dir/text" && exit 1;
  local/train_lms.sh --ngram-order $ngram_order \
    $extra_text_dir $extra_text_dir/lm_${ngram_order}gram
fi


echo "LM interpolation......"
if [ ! -f $lm_dir/${ngram_order}gram_mincount_mixed_lm.gz ]; then
  for d in $local_text_dir/lm_${ngram_order}gram $extra_text_dir/lm_${ngram_order}gram; do
    ngram -debug 2 -order $ngram_order -unk -lm $d/${ngram_order}gram-mincount/lm_unpruned.gz \
      -ppl $heldout > $d/${ngram_order}gram-mincount/lm.ppl ;
  done
  compute-best-mix $local_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm.ppl \
    $extra_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm.ppl > $lm_dir/best-mix.ppl
  echo "local:extra=0.8:0.2" > $lm_dir/mix.pair

  ngram -order $ngram_order -unk \
    -lm $local_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz -lambda 0.8 \
    -mix-lm $extra_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz \
    -write-lm $lm_dir/${ngram_order}gram_mincount_mixed_lm.gz

  ngram -debug 2 -order $ngram_order -unk -lm $lm_dir/${ngram_order}gram_mincount_mixed_lm.gz -ppl $heldout > $lm_dir/lm.ppl
fi
