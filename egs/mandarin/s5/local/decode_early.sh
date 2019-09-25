#!/bin/bash

iter=160_decode
stage=3
lang=data/lang_with_giga_test
dev_name="dev_hires"
dir=exp/chain_cleanup/tdnn_1d_sp
graph_dir=$dir/graph_${iter}
ivec_dir=exp/nnet3_cleanup/ivectors_dev_hires_nopitch
. cmd.sh
. path.sh
iter_opts="--iter $iter"
nj=40

if [ $stage -le 1 ]; then
mkgraph_early_model.sh --self-loop-scale 1.0 --remove-oov \
  $lang $dir $dir/$iter.mdl $graph_dir
	fstrmsymbols --apply-to-output=true --remove-arcs=true "echo 3|" $graph_dir/HCLG.fst - | \
		fstconvert --fst_type=const > $graph_dir/temp.fst
	mv $graph_dir/temp.fst $graph_dir/HCLG.fst
fi

steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	--nj $nj --cmd "$decode_cmd" $iter_opts \
	--online-ivector-dir $ivec_dir \
	$graph_dir data/$dev_name $dir/decode_${dev_name}_iter_${iter}_with_giga_test || exit 1

