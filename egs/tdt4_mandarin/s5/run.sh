#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0

. ./path.sh
. ./cmd.sh
. utils/parse_options.sh

stage=4
num_jobs=32
num_jobs_decode=32

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
  local/tdt4_data_prep_split.sh data/local/ || exit 1;
fi

if [ $stage -le 1 ]; then
########################################################################
#                       Lexicon preparation
########################################################################
  local/gale_prep_dict.sh || exit 1;
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
fi

if [ $stage -le 2 ]; then
########################################################################
#                       LM training
########################################################################
# Text is too few to use KN smoothing, using W-B, will add more text from gale_mandarin later
  local/tdt4_mandarin_train_lms.sh --extra-text data/local/gale_text
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

fi
