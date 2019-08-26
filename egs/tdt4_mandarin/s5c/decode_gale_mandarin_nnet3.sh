#/bin/bash



stage=0
nj=40
upsample=true
. path.sh
. cmd.sh
. utils/parse_options.sh

eg_dir="../../gale_mandarin/s5"
graph_dir="exp/tri5a/graph"
decode_dir="exp/nnet3/tdnn_sp/decode_gale_mandarin"
ivector_extractor="exp/nnet3/extractor"
ivector_dir="exp/nnet3/ivectors_dev_gale_mandarin"

dev_dir=$eg_dir/data/dev_hires
conf_dir=$eg_dir/conf
decode_config=$conf_dir/decode.config
mfcc_config=$conf_dir/mfcc_hires.conf
online_conf=$conf_dir/online.conf




if [ $stage -le 0 ]; then
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    ${dev_dir}_nopitch $ivector_extractor $ivector_dir
fi

if [ $stage -le 1 ]; then
  steps/nnet3/decode.sh --nj $nj --cmd "$decode_cmd" \
    --config $decode_config --online-ivector-dir $ivector_dir \
    $graph_dir $dev_dir $decode_dir \
	  > decode_hkust.log 2>&1
fi

