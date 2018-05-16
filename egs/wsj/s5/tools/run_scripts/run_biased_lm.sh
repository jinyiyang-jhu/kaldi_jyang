#!/bin/bash

. cmd.sh
dataname="dev_20spk_refined"
datadir="./data"
data=$datadir/$dataname
lang="./data/lang"
top_n_words=100
srcdir="./exp/tri5a"
graphdir="./exp/tri5a_biased_lm_${dataname}_top_${top_n_words}"
nj=32
cmd=$decode_cmd
min_word_per_graph=1

split_graph_dir=${graphdir}_${dataname}_top_${top_n_words} 



./steps/cleanup/make_biased_lm_graphs.sh \
    --nj $nj --cmd $decode_cmd \
    --top-n-words $top_n_words \
    --min-words-per-graph $min_word_per_graph \
    $data $lang $srcdir $graphdir
