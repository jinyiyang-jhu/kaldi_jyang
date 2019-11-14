ac_dir="/export/b07/jyang/kaldi-jyang/kaldi/egs/mandarin/s5/"
stage=2
lang_original=data/lang_with_giga_decode
lang=${lang_original}_chain
dir=exp/chain_cleanup/tdnn_1d_sp
graph_dir=exp/chain_cleanup/tdnn_1d_sp/graph_with_giga_large_lex
dev_name="dev_hires"
dev_ivector_dir=$ac_dir/exp/nnet3_cleanup/ivectors_dev_hires_nopitch
decode_nj=40

. path.sh
. cmd.sh
utils/parse_options.sh


if [ $stage -le 0 ]; then
  echo "$0: creating lang directory with one state per phone."
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  if [ -d $lang ]; then
    if [ $lang/L.fst -nt $lang_original/L.fst ]; then
      echo "$0: $lang already exists, not overwriting it; continuing"
    else
      echo "$0: $lang already exists and seems to be older than data/lang..."
      echo " ... not sure what to do.  Exiting."
      exit 1;
    fi
  else
    cp -r $lang_original $lang
    silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
    nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
    # Use our special topology... note that later on may have to tune this
    # topology.
    steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang/topo
  fi
fi

if [ $stage -le 1 ];then
  echo "Making graph"
  utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov $lang $dir $graph_dir || exit 1;
  fstrmsymbols --apply-to-output=true --remove-arcs=true "echo 3|" $graph_dir/HCLG.fst - | \
    fstconvert --fst_type=const > $graph_dir/temp.fst
  mv $graph_dir/temp.fst $graph_dir/HCLG.fst
fi

echo "Decoding"
iter_opts=
steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	--nj $decode_nj --cmd "$decode_cmd" $iter_opts \
	--online-ivector-dir $dev_ivector_dir \
	$graph_dir data/$dev_name \
  $dir/decode_${dev_name}_with_giga_large_lex || exit 1
echo "Decoding done !"

