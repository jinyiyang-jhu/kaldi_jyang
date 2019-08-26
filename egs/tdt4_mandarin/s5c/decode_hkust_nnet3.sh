#/bin/bash



stage=0
nj=30
upsample=true
. path.sh
. cmd.sh
. utils/parse_options.sh

eg_dir="../../hkust/s5"
graph_dir="exp/tri5a/graph"
decode_dir="exp/nnet3/tdnn_sp/decode_hkust"
ivector_extractor="exp/nnet3/extractor"
ivector_dir="exp/nnet3/ivectors_dev_hkust"

conf_dir=$eg_dir/conf_16k
dev_dir=$eg_dir/data/dev_hires
new_dev_dir=$eg_dir/data/dev_hires_16k
feat_dir=$eg_dir/exp/make_hires/dev_hires_16k
mfcc_dir=$eg_dir/mfcc_hires
decode_config=$conf_dir/decode.config
mfcc_config=$conf_dir/mfcc_hires.conf
online_conf=$conf_dir/online.conf



if [ $stage -le 0 ]; then
  utils/copy_data_dir.sh $dev_dir $new_dev_dir
  awk '{print $0." sox -r 8000 - -r 16000 -t wav - |"}' $dev_dir/wav.scp > $new_dev_dir/wav.scp
  steps/make_mfcc_pitch_online.sh --nj $nj --cmd "$train_cmd" \
    --mfcc-config $mfcc_config $new_dev_dir \
    $feat_dir $mfcc_dir || exit 1;
  steps/compute_cmvn_stats.sh $new_dev_dir $feat_dir $mfcc_dir
  utils/data/limit_feature_dim.sh 0:39 $new_dev_dir ${new_dev_dir}_nopitch
  steps/compute_cmvn_stats ${new_dev_dir}_nopitch $feat_dir $mfcc_dir
fi

if [ $stage -le 1 ]; then
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    ${new_dev_dir}_nopitch $ivector_extractor $ivector_dir
fi

if [ $stage -le 2 ]; then
  steps/nnet3/decode.sh --nj $nj --cmd "$decode_cmd" \
    --config $decode_config --online-ivector-dir $ivector_dir \
    $graph_dir $new_dev_dir $decode_dir \
	  > decode_hkust.log 2>&1
fi

