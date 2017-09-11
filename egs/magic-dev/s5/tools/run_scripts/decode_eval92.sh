#!/bin/bash

min_lmwt=7
max_lmwt=17
cmd="run.pl"

root="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5"
dir=`pwd`/exp/nnet5c/decode_tgpr_5k_eval92
lang_or_graph=`pwd`/exp/tri2b_clean/graph_tgpr_5k
data=$root/data/test_eval92

symtab=$lang_or_graph/words.txt
suffix=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d");

$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/split.LMWT.log \
   bash $root/tools/split_eval92.sh $dir/scoring LMWT.tra || exit 1;

for s in "${suffix[@]}"
do
        cat ${data}_${s}/text | sed 's:<NOISE>::g' | sed 's:<SPOKEN_NOISE>::g' > $dir/scoring_subset_${s}/test_filt.txt
	$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_subset_${s}/log/score.LMWT.log \
	     	cat $dir/scoring_subset_${s}/LMWT.tra \| \
	    	utils/int2sym.pl -f 2- $symtab \| sed 's:\<UNK\>::g' \| \
	    	compute-wer --text --mode=present \
	   	ark:$dir/scoring_subset_${s}/test_filt.txt  ark,p:- ">&" $dir/scoring_subset_${s}/wer_LMWT || exit 1;
done
