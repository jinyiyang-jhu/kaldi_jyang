#!/bin/bash

# Create a decoding graph, use the acoustic model trained on whole training
# data, while LM is trained on (k-1)/k of the whole training data. Decode the
# whole training data with the new decoding graph to get lattices of training
# data, used for training Lattice Transformer.

nnet3_affix=
chunk_width=140,100,160

dir=exp/chain/multipsplice_tdnn
rnnlmdir=exp/rnnlm_lstm_tdnn_1b
lang_dir=data/lang_test
graph_name=graph_fsp_train
gmm=tri5a
tree_dir=exp/chain/${gmm}_tree
decode_dir=exp/chain/multipsplice_tdnn/decode_train_hire_nosp_${graph_name}
stage=-2
nj=80
graph_dir=exp/chain/tri5a_tree/graph_fsp_train
. cmd.sh
. path.sh

frames_per_chunk=$(echo $chunk_width | cut -d, -f1)

if [ $stage -le 0 ]; then
  echo "Genearating train MFCC hires"
  utils/copy_data_dir.sh data/train data/train_hires
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" data/train_hires
  steps/compute_cmvn_stats.sh data/train_hires
  utils/fix_data_dir.sh data/train_hires
fi

if [ $stage -le 1 ]; then 
  echo "Getting ivectors for train MFCC hires"
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
      data/train_hires exp/nnet3${nnet3_affix}/extractor \
      exp/nnet3${nnet3_affix}/ivectors_train_hires
fi

if [ $stage -le 2 ]; then  
  echo "Decoding train hires"
  for lmtype  in fsp_train; do
    steps/nnet3/decode.sh \
      --acwt 1.0 --post-decode-acwt 10.0 \
      --extra-left-context 0 --extra-right-context 0 \
      --extra-left-context-initial 0 \
      --extra-right-context-final 0 \
      --frames-per-chunk $frames_per_chunk \
      --nj 80 --cmd "$decode_cmd"  --num-threads 4 \
      --online-ivector-dir exp/nnet3/ivectors_train_hires \
      $tree_dir/graph_${lmtype} data/train_hires ${dir}/decode_${lmtype}_train || exit 1;
    echo "Decoding train hires with RNN rescoring"
    bash rnnlm/lmrescore_pruned.sh \
      --cmd "$decode_cmd --mem 8G" \
      --weight 0.45 --max-ngram-order 4 \
      $lang_dir $rnnlmdir \
      data/train_hires ${dir}/decode_${lmtype}_train \
      $dir/decode_rnnLM_${lmtype}_train || exit 1;

    echo "Decoding train hires with RNN nbest rescoring"
    bash rnnlm/lmrescore_nbest.sh 1.0 data/lang_test $rnnlmdir data/train_hires/ \
      ${dir}/decode_${lmtype}_train $dir/decode_rnnLM_nbest_${lmtype}_train || exit 1;
  done
fi
