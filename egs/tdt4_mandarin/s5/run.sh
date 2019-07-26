#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0

. ./path.sh
. ./cmd.sh
. utils/parse_options.sh

stage=0
num_jobs=16
num_jobs_decode=32

#AUDIO=(
#  /export/corpora/LDC/LDC2005S11/TDT4_MAN_1
#  /export/corpora/LDC/LDC2005S11/TDT4_MAN_2
#  /export/corpora/LDC/LDC2005S11/TDT4_MAN_3
#  /export/corpora/LDC/LDC2005S11/TDT4_MAN_4
#)
AUDIO=/export/corpora/LDC/LDC2005S11
TEXT=export/corpora/LDC/LDC2005T16

set -e -o pipefail
set -x

local/tdt4_data_prep_audio.sh $AUDIO
#local/tdt4_data_prep_text.sh $TEXT

