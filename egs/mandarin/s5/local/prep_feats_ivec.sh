#!/bin/bash

. path.sh
. cmd.sh

nj=50

eval_name=vast_eval
ivector_dir=exp/nnet3_cleanup
ivector_extractor=$ivector_dir/extractor

# Extract feats for VAST
mfccdir=mfcc
utils/fix_data_dir.sh data/$eval_name
steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $nj \
  data/$eval_name exp/make_mfcc/$eval_name $mfccdir
steps/compute_cmvn_stats.sh data/$eval_name exp/make_mfcc/$eval_name $mfccdir
utils/fix_data_dir.sh data/$eval_name

# Extract hires feats for VAST
utils/copy_data_dir.sh data/$eval_name data/${eval_name}_hires
mfccdir=mfcc_hires_sp
eval_name=${eval_name}_hires

# Extract feats for higher resolution
steps/make_mfcc_pitch_online.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
  --cmd "$train_cmd" data/$eval_name exp/make_hires_sp/$eval_name $mfccdir || exit 1
steps/compute_cmvn_stats.sh data/$eval_name exp/make_hires_sp/$eval_name $mfccdir
utils/fix_data_dir.sh data/$eval_name

# Make MFCC data dir without pitch to extract iVector
utils/data/limit_feature_dim.sh 0:39 data/$eval_name data/${eval_name}_nopitch || exit 1;
steps/compute_cmvn_stats.sh data/${eval_name}_nopitch exp/make_hires_sp/${eval_name}_nopitch $mfccdir || exit 1;


# Extract ivectors
steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
  data/${eval_name}_nopitch $ivector_extractor $ivector_dir/ivectors_${eval_name}_nopitch || exit 1

echo "Feats, and ivectors prepared successfully!"
