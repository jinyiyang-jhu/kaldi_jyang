#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0

. ./path.sh
. ./cmd.sh
. utils/parse_options.sh

stage=0
num_jobs=32
num_jobs_decode=32

AUDIO=/export/corpora/LDC/LDC2005S11
TEXT=/export/corpora/LDC/LDC2005T16

set -e -o pipefail
set -x

#########################################################
#                       Data preparation
#########################################################
#local/tdt4_data_prep_audio.sh $AUDIO || exit 1;
#local/tdt4_data_prep_text.sh $TEXT || exit 1;
#local/tdt4_data_prep_split.sh data/local/ || exit 1;

#########################################################
#                       Lexicon preparation
#########################################################
#local/hkust_prepare_dict.sh || exit 1;
#utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

#########################################################
#                       LM training
#########################################################
# Text is too few to use KN smoothing, using W-B, will add more text from gale_mandarin
# later
#local/tdt4_mandarin_train_lms.sh

#local/tdt4_mandarin_format_data.sh


#########################################################
#                      Extract MFCC plus pitch features
#########################################################
for x in train dev ; do
  utils/fix_data_dir.sh data/$x
  steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $num_jobs \
    data/$x exp/make_mfcc/$x $mfccdir
  utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done
