#!/bin/bash

# This script will clean up the training data, using provided acoustic model
# (e.g., Gale_mandarin or HKUST)

nj=32
. cmd.sh
. path.sh
. utils/parse_options.sh

set -e -o pipefail
if [ $# -ne 5 ]; then
    echo "Usage: $0 <train-data-dir> <lang-dir> <srcdir> <dir> <cleaned-data>"
    echo "E.g., $0 [options] data/train data/lang <gale_mandir_mdl_dir> exp/gale_mandarin data/train_clean"
    exit 1;
fi

train_data_dir=$1
lang_dir=$2
srcdir=$3
newdir=$4
clean_data_dir=$5

steps/cleanup/segment_long_utterances.sh --nj ${nj} --cmd "$train_cmd" \
  --max-bad-proportion 0.6 $srcdir $lang_dir $train_data_dir \
  $clean_data_dir $newdir || exit 1;

#steps/cleanup/clean_and_segment_data.sh --nj ${nj} --cmd "$train_cmd" \
#  --segmentation-opts "--min-segment-length 0.3 --min-new-segment-length 0.6" \
#  $train_data_dir $lang_dir $srcdir $newdir $clean_data_dir || exit 1;
echo "Clean up succeeded !"

