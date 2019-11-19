#!/bin/bash

ngram_order=4
oov_sym="<UNK>"
extra_lm_dir=""
. path.sh
. utils/parse_options.sh

if [ $# != 4 ]; then
  echo "Usage: [--ngram-order ] [--extra-lm-src ] <dict-dir> <src-dir> <lm-dir> <dev-dir>"
  echo "E.g. $0 --ngram-order 4 --oov-sym \"<UNK>\" --extra-lm
  \"data/local/gigaword_chinese\" data/local/dict data/local/train data/local/lm data/dev "
  exit 1
fi

dict_dir=$1
local_text_dir=$2
lm_dir=$3_${ngram_order}gram
heldout=$4/text

# check if sri is installed or no
#which ngram-count  &>/dev/null
#if [[ $? == 0 ]]; then
#  echo "srilm installed"
#else
#  echo "Please install srilm first !"
#  exit 1
#fi

echo "Building $ngram_order gram LM"
[ ! -d $lm_dir ] && mkdir -p $lm_dir exit 1;

if [ ! -f $lm_dir/${ngram_order}gram-mincount/lm_unpruned.gz ]; then
  echo "Training LM with train text"
  [ ! -f $local_text_dir/text ] && echo "No $local_text_dir/text" && exit 1;
	awk '{i=$2;for (n=3;n<=NF;++n){i=i" "$n;}print i}' $local_text_dir/text > $lm_dir/text
  local/train_lms.sh --ngram-order $ngram_order $lm_dir $dict_dir $lm_dir $heldout
fi

if [ ! -z $extra_lm_dir ]; then
  [ ! -d $extra_text_dir/lm_${ngram_order}gram ] && mkdir -p $extra_text_dir/lm_${ngram_order}gram && exit 1
  if [ ! -f $extra_lm_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz ]; then
    echo "Training LM with extra text"
    [ ! -f $extra_lm_dir/text ] && echo "No $extra_lm_dir/text" && exit 1;
    local/train_lms.sh --ngram-order $ngram_order \
    $extra_lm_dir $dict_dir $extra_lm_dir/lm_${ngram_order}gram $heldout
  fi

lm_dir_inter=${lm_dir}_interpolated
  echo "LM interpolation......"
  if [ ! -f $lm_dir_inter/${ngram_order}gram_mincount_mixed_lm.gz ]; then
    for d in $lm_dir $extra_text_dir/lm_${ngram_order}gram; do
      ngram -debug 2 -order $ngram_order -unk -lm $d/${ngram_order}gram-mincount/lm_unpruned.gz \
        -ppl $heldout > $d/${ngram_order}gram-mincount/lm.ppl ;
    done
    compute-best-mix $lm_dir/${ngram_order}gram-mincount/lm.ppl \
      $extra_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm.ppl > $lm_dir_inter/best-mix.ppl
    echo "local:extra=0.8:0.2" > $lm_dir_inter/mix.pair
    ngram -order $ngram_order -unk -map-unk $oov_sym \
      -lm $lm_dir/${ngram_order}gram-mincount/lm_unpruned.gz -lambda 0.8 \
      -mix-lm $extra_text_dir/lm_${ngram_order}gram/${ngram_order}gram-mincount/lm_unpruned.gz \
      -write-lm $lm_dir_inter/${ngram_order}gram_mincount_mixed_lm.gz

    ngram -debug 2 -order $ngram_order -unk \
    -lm $lm_dir_inter/${ngram_order}gram_mincount_mixed_lm.gz \
    -ppl $heldout > $lm_dir_inter/lm.ppl
  fi
fi
