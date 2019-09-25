#!/bin/bash

# Report WER for reports and conversational
# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0

if [ $# -ne 1 ]; then
   echo "Arguments should be the <dev-dir>  see ../run.sh for example."
   exit 1;
fi

[ -f ./path.sh ] && . ./path.sh

set -o pipefail -e

#galeFolder=$(utils/make_absolute.sh $1)
dev_dir=$1

mkdir -p $dev_dir/analysis
for type in $(ls -1 local/test.* | xargs -n1 basename); do
  for x in $dev_dir/feats.scp $dev_dir/wav.scp; do
    cat $x | grep -f local/$type > $dev_dir/analysis/${type}_$(basename $x)
  done
  feat-to-len scp:$dev_dir/analysis/${type}_feats.scp | awk '{print $1/100/3600}' \
    > $dev_dir/analysis/${type}_feats.len
done
