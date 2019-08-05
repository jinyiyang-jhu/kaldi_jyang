#!/bin/bash

# Copyright 2019 (author: Jinyi Yang)
# Apache 2.0


. path.sh
. ./utils/parse_options.sh
if [ $# != 2 ]; then
   echo "Usage: $0 [options] <tmp_data_dir> <tgt_data_dir>";
   echo "e.g.: $0 data/local data"
   exit 1;
fi

set -e -o pipefail

tmpdir=$1
tgtdir=$2

for f in $tmpdir/all.uttid $tmpdir/all.wav.scp $tmpdir/all.text \
    $tmpdir/all.spk2utt $tmpdir/all.utt2spk $tmpdir/all.segments; do
    if [ ! -f $f ]; then
      echo "$0: expected file $f to exist !"
      exit 1;
    fi
done

mkdir -p $tmpdir/train || exit 1;
mkdir -p $tmpdir/dev || exit 1;
grep -f <(cat local/dev.*.list) $tmpdir/all.uttid  | grep -v -F -f local/bad_utts > $tmpdir/dev/uttid
grep -v -f <(cat local/dev.*.list) $tmpdir/all.uttid | grep -v -F -f local/bad_utts > $tmpdir/train/uttid

grep -f <(cat local/dev.*.list) $tmpdir/all.wav.scp | grep -v -F -f local/bad_utts > $tmpdir/dev/wav.scp
grep -v -f <(cat local/dev.*.list) $tmpdir/all.wav.scp | grep -v -F -f local/bad_utts > $tmpdir/train/wav.scp

for x in dev train; do
  outdir=$tmpdir/$x
  for f in "text" "utt2spk" "segments"; do
    utils/filter_scp.pl -f 1 $outdir/uttid $tmpdir/"all.$f" > $outdir/"$f"
  done
  utils/utt2spk_to_spk2utt.pl $outdir/utt2spk | sort -u > $outdir/spk2utt
  [ -d $tgtdir/$x ] && rm -r $tgtdir/$x
  cp -r $tmpdir/$x $tgtdir/$x
done

echo "Data split succeeded !"

