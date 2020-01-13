#!/bin/bash

ac_dir="/export/b07/jyang/kaldi-jyang/kaldi/egs/gale_tdt_mandarin/s5/"
stage=1
lang=data/lang_large_test_chain
dir=decode_test_336/chain_cleanup/tdnn_1d_sp
graph_dir=$dir/graph_large_test_chain
dev_names=("dev_hires" "eval_hires" "ywang/dev_man_hires" "ywang/dev_sge_hires")
ivec_names=("dev_hires" "eval_hires" "ywang_dev_man_hires" "ywang_dev_sge_hires")
decode_nj=10

. path.sh
. cmd.sh
. parse_options.sh


if [ $stage -le 1 ];then
  echo "Making graph"
  utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov $lang $dir $graph_dir || exit 1;
  fstrmsymbols --apply-to-output=true --remove-arcs=true "echo 3|" $graph_dir/HCLG.fst - | \
    fstconvert --fst_type=const > $graph_dir/temp.fst
  mv $graph_dir/temp.fst $graph_dir/HCLG.fst
fi

echo "Decoding"
iter_opts=
for var in $(seq 0 ${#dev_names[@]}); do
	dev_name=${dev_names[$var]}
  echo "Decoding $dev_name"
	dev_ivector_dir=$ac_dir/exp/nnet3_cleanup/ivectors_${ivec_names[$var]}_nopitch
	steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
		--nj $decode_nj --cmd "$decode_cmd" $iter_opts \
		--online-ivector-dir $dev_ivector_dir \
		$graph_dir data/$dev_name \
  	$dir/decode_${ivec_names[$var]}_large_test_chain || exit 1
done
echo "Decoding done !"

