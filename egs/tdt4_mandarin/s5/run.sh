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
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

#########################################################
# 
#########################################################

