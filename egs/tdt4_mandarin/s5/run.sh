#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0

. ./path.sh
. ./cmd.sh
. utils/parse_options.sh

stage=4
num_jobs=32
num_jobs_decode=32
train_nj=32
decode_nj=4
extra_text=data/loca/gale_text

AUDIO=/export/corpora/LDC/LDC2005S11
TEXT=/export/corpora/LDC/LDC2005T16

set -e -o pipefail
set -x

if [ $stage -le 0 ]; then
#########################################################
#                       Data preparation
#########################################################
  local/tdt4_data_prep_audio.sh $AUDIO || exit 1;
  local/tdt4_data_prep_text.sh $TEXT || exit 1;
  local/tdt4_data_prep_split.sh data/local/ data/ || exit 1;
fi

if [ $stage -le 1 ]; then
########################################################################
#                       Lexicon preparation
########################################################################
  local/tdt4_mandarin_prep_dict.sh --extra-text $extra_text|| exit 1;
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
fi

if [ $stage -le 2 ]; then
########################################################################
#                       LM training
########################################################################
# Text is too few to use KN smoothing, using W-B, will add more text from gale_mandarin later
  local/tdt4_mandarin_train_lms.sh --extra-text $extra_text
  local/tdt4_mandarin_format_data.sh
fi

if [ $stage -le 3 ]; then
########################################################################
#                      Extract MFCC plus pitch features
########################################################################
  for x in train dev ; do
    utils/fix_data_dir.sh data/$x
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $num_jobs \
      data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
  done
fi

utils/fix_data_dir.sh data/train || exit 1;
if [ $stage -le 4 ]; then
########################################################################
#                      Monophone training
########################################################################
#utils/subset_data_dir.sh --first data/train 4000 data/train_4k || exit 1;
  #steps/train_mono.sh --cmd "$train_cmd" --nj $train_nj \
  #  data/train data/lang exp/mono || exit 1;
# Monophone decode
  #utils/mkgraph.sh data/lang_test exp/mono exp/mono/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $decode_nj \
    exp/mono/graph data/dev exp/mono/decode
# Monophone align
  steps/align_si.sh --cmd "$train_cmd" --nj $train_nj \
    data/train data/lang exp/mono exp/mono_ali || exit 1;
fi

if [ $stage -le 5 ]; then
########################################################################
#                      Triphone training
########################################################################
  steps/train_deltas.sh --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;
  # Decode tri1
  utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd"  --nj $decode_nj \
    exp/tri1/graph data/dev exp/tri1/decode
  # Align tri1
  steps/align_si.sh --cmd "$train_cmd" --nj $train_nj \
    data/train data/lang exp/tri1 exp/tri1_ali || exit 1;
fi

if [ $stage -le 6 ]; then
########################################################################
#                      Triphone [delta+delta]training
########################################################################
  steps/train_deltas.sh --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/tri1_ali exp/tri2 || exit 1; 
  # Decode tri2
  utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph
  steps/decode.sh --cmd "$decode_cmd" --nj $decode_nj \
    exp/tri2/graph data/dev exp/tri2/decode
  # Align tri2
  steps/align_si.sh --cmd "$train_cmd" --nj $train_nj \
    data/train data/lang exp/tri2 exp/tri2_ali || exit 1;
fi

if [ $stage -le 7 ]; then
########################################################################
#                      Triphone [LDA+MLLLT]training
########################################################################
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/tri2_ali exp/tri3a || exit 1;
  # Decode tri3a
  utils/mkgraph.sh data/lang_test exp/tri3a exp/tri3a/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $decode_nj \
    exp/tri3a/graph data/dev exp/tri3a/decode
  # Align tri3a 
  steps/align_fmllr.sh --cmd "$train_cmd" --nj $train_nj \
    data/train data/lang exp/tri3a exp/tri3a_ali || exit 1;
fi

if [ $stage -le 8 ]; then
########################################################################
#                      Triphone [SAT]training
########################################################################
  steps/train_sat.sh --cmd "$train_cmd" \
    2500 20000 data/train data/lang exp/tri3a_ali exp/tri4a || exit 1;
  # Decode tri4a 
  utils/mkgraph.sh data/lang_test exp/tri4a exp/tri4a/graph
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj $decode_nj \
    exp/tri4a/graph data/dev exp/tri4a/decode
  # Align tri4a
  steps/align_fmllr.sh  --cmd "$train_cmd" --nj $decode_nj \
    data/train data/lang exp/tri4a exp/tri4a_ali
fi

if [ $stage -le 9 ]; then
########################################################################
#                      Triphone [SAT]training
########################################################################
  steps/train_sat.sh --cmd "$train_cmd" \
    3500 100000 data/train data/lang exp/tri4a_ali exp/tri5a || exit 1;
  # Decode tri5a 
  utils/mkgraph.sh data/lang_test exp/tri5a exp/tri5a/graph
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj $decode_nj \
    exp/tri5a/graph data/dev exp/tri5a/decode
  # Align tri4a
  steps/align_fmllr.sh  --cmd "$train_cmd" --nj $decode_nj \
    data/train data/lang exp/tri5a exp/tri5a_ali
fi
