#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0


. path.sh
. ./utils/parse_options.sh
if [ $# != 2 ]; then
   echo "Usage: $0 [options] <tmp_data_dir> <tgt_data_dir>";
   echo "e.g.: $0 TDT2 data/local/tdt2"
   exit 1;
fi

set -e -o pipefail

tdtdir=$1
tgtdir=$2
mkdir -p $tgtdir

for f in $tdtdir/all.uttid $tdtdir/all.wav.scp $tdtdir/all.text \
    $tdtdir/all.spk2utt $tdtdir/all.utt2spk $tdtdir/all.segments; do
    if [ ! -f $f ]; then
      echo "$0: expected file $f to exist !"
      exit 1;
    fi
done

cat $tdtdir/all.uttid | grep -v -F -f local/bad_utts > $tgtdir/uttid


for f in "text" "utt2spk" "segments"; do
  cp $tdtdir/"all.$f"  $tgtdir/"$f"
done
awk 'NR==FNR{a[$2];next} $1 in a{print $0}' $tgtdir/segments
$tgtdir/all.wav.scp | grep -v -F -f local/bad_utts > $tgtdir/wav.scp
#cat $tdtdir/all.wav.scp | grep -v -F -f local/bad_utts > $tgtdir/wav.scp
utils/utt2spk_to_spk2utt.pl $tgtdir/utt2spk | sort -u > $tgtdir/spk2utt
cat $tdtdir/all.wav.scp | grep -v -F -f local/bad_utts > $tgtdir/wav.scp

echo "Data prepare succeeded !"

