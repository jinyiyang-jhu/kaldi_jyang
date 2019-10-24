#!/bin/bash

# 2019 Johns Hopkins University (Jinyi Yang)

stage=0
oov_sym="<UNK>"
cmd="run.pl"
nj=16
. path.sh
. cmd.sh
. parse_options.sh

if [ $# != 6 ]; then
  echo "Usage: $0 [--oov-sym] <word-list> <subword-list> <pair-code> <subword-lang-tmp-dir> <subword-lat-dir> <word-lat-dir>"
  echo "E.g. $0 --oov-sym=<UNK> data/lang_word/words.txt data/lang_subword/words.txt data/lang_subword/pair_code.txt "
  echo "data/lang_subword_to_word exp/tri3b/decode_test_subword exp/tri3b/decode_test_subword_to_word_lat"
  exit 1;
fi

words=$1
subwords=$2
pair_code=$3
subword_lex_dir=$4
subword_lat_dir=$5
word_lat_dir=$6

[ ! -d $word_lat_dir ] && mkdir -p $word_lat_dir && exit 1;

nj=`ls $subword_lat_dir/lat.*.gz | wc -l`

if [ $stage -le 1 ]; then
  echo "Preparing word to subword lexicon and stops list"
  utils/subword/prepare_lex_subword_to_word.sh --oov-sym=$oov_sym \
    $words $subword $pair_code $subword_lex_dir
fi

if [ $stage -le 2 ]; then
  oov_int=`cat $subword_lex_dir/oov.int`
  echo "Converting subword lattice to word lattice"
  $cmd JOB=1:$nj $word_lat_dir/log/convert-word-lat.JOB.log \
    lattice-bpe-to-word --unk-int=$oov_int \
    $subword_lex_dir/lexicon_words_to_subwords.int $subword_lex_dir/stops.int \
    "ark:gunzip -c $subword_lat_dir/lat.JOB.gz |" "ark:|gzip -c >$word_lat_dir/lat.JOB.gz" || exit 1;
fi

echo "Converting subword lattice to word lattice done !"

