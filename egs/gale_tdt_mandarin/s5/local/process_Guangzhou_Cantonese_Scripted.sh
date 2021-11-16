#!/bin/bash




# Get MFCC
nj=10
stage=2
affix=1d
nnet3_affix=_cleanup
lang_affix="_large_test"
dir=exp/chain${nnet3_affix}/tdnn${affix:+_$affix}_sp
dset="Guangzhou_Cantonese_Scripted_Speech"
data=data
mfccdir=mfcc/$dset

. path.sh
. cmd.sh
. parse_options.sh

if [ $stage -le 0 ]; then
  # Get wav.scp, text, spk2utt, utt2spk
  python3 local/process_Guangzhou_Cantonese_Scripted.py
fi

if [ $stage -le 1 ]; then
    datadir=$data/$dset
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $nj \
      $datadir exp/make_mfcc/${dset} $mfccdir || exit 1
    utils/fix_data_dir.sh $datadir # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh $datadir exp/make_mfcc/${dset} $mfccdir/${dset}
fi

if [ $stage -le 2 ]; then
  mfccdir=mfcc_hires_sp/$dset
  utils/copy_data_dir.sh $data/$dset $data/${dset}_hires
  steps/make_mfcc_pitch_online.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" $data/${dset}_hires exp/make_hires_sp/$data/${dset}_hires \
    $mfccdir/${dset}_hires || exit 1
  steps/compute_cmvn_stats.sh $data/${dset}_hires \
    exp/make_hires_sp/$data/${dset}_hires $mfccdir/${dset}_hires
  utils/fix_data_dir.sh $data/${dset}_hires
  utils/data/limit_feature_dim.sh 0:39 $data/${dset}_hires $data/${dset}_hires_nopitch || exit 1;
  steps/compute_cmvn_stats.sh $data/${dset}_hires_nopitch \
    exp/make_hires_sp/$data/${dset}_hires_nopitch $mfccdir/${dset}_hires_nopitch || exit 1;
fi

if [ $stage -le 3 ]; then
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    $data/${dset}_hires_nopitch exp/nnet3${nnet3_affix}/extractor \
    exp/nnet3${nnet3_affix}/ivectors_${dset}_hires_nopitch
fi

if [ $stage -le 4 ]; then
  iter_opts=
  dir=exp/chain${nnet3_affix}/tdnn${affix:+_$affix}_sp
  graph_dir=$dir/graph${lang_affix}

  ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${dset}_hires_nopitch
  decode_dir=$dir/decode_large_test/${dset}
  # steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
  #   --nj $nj --cmd "$decode_cmd" $iter_opts \
  #   --online-ivector-dir "$ivector_dir" \
  #   $graph_dir $data/${dset}_hires $decode_dir || exit 1

  pruned=_pruned
  rnnlmdir=exp/rnnlm_lstm_1a
  rnnlm/lmrescore$pruned.sh \
      --cmd "$decode_cmd --mem 8G" \
      --weight 0.45 --max-ngram-order 4 \
      data/lang_large_test $rnnlmdir \
      $data/${dset}_hires ${decode_dir} \
      ${decode_dir}_rnnlm_1a_rescore
#    rnnlm/lmrescore_nbest.sh \
#        --cmd "$decode_cmd --mem 8G" --N 20 \
#        0.4 data/lang_large_test $rnnlmdir \
#        $datadir/${x}_hires ${decode_dir} \
#        ${decode_dir}_rnnlm_1a_nbest_rescore
  #done
  #done
fi
