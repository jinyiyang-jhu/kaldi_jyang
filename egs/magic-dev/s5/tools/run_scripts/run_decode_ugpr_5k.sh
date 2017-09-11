#!/bin/bash

suffix=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d");

. ./cmd.sh
cmd=run.pl
stage=0
nj=8

classes_to_pseduo_map=phone_mappings/map_root_int-vs-dep_phone_int.map
mdl=exp/nnet5c/final.mdl
graphdir=exp/tri2b_clean/graph_ugpr_5k
num_of_classes=`wc -l $classes_to_pseduo_map | cut -d " " -f 1`

for s in "${suffix[@]}"
do
(
datadir=data/test_eval92_${s} 
decodedir=exp/nnet5c/decode_ugpr_5k_eval92_subset_${s}
postdir=post/nnet5c/word_ugpr_5k_subset_${s}

if [ $stage -le 0 ]; then
  steps/nnet2/decode.sh --cmd "$decode_cmd" --nj 8 \
     $graphdir $datadir $decodedir
fi

if [ $stage -le 1 ]; then
   $cmd JOB=1:$nj $postdir/log/lats_post.JOB.log \
   lattice-to-post --acoustic-scale=0.1 ark:"gunzip -c $decodedir/lat.JOB.gz |" ark,t:$postdir/lat.JOB.post || exit 1;
   $cmd JOB=1:$nj $postdir/log/phone_post.JOB.log \
   post-to-phone-post $mdl ark:$postdir/lat.JOB.post ark,t:$postdir/lat.JOB.phone.post || exit 1;
fi

if [ $stage -le 2 ]; then
	echo "Stage 2: compute phone post matrix"
	for n in $(seq $nj)
	do
	  (
		perl tools/post_from_lats/lats_phone_post_to_matrix.pl $postdir/lat.$n.phone.post $classes_to_pseduo_map $num_of_classes $postdir/lat.$n.phone.post.matrix || exit 1;
          ) &
         done
         wait 
fi
) &
done
wait

exit 0;
