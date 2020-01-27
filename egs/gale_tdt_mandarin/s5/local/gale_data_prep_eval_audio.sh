#!/bin/bash

# Copyright 2014 QCRI (author: Ahmed Ali)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Apache 2.0


echo $0 "$@"
eval_audio_dir=$1
galeData=$2
wavedir=$galeData/wav
mkdir -p $wavedir
# check that sox is installed
which sox  &>/dev/null
if [[ $? != 0 ]]; then
 echo "$0: sox is not installed"
 exit 1
fi

set -e -o pipefail

#ls $eval_audio_dir/*.flac
ls $eval_audio_dir/*.flac | while read file; do
  f=$(basename $file)
  if [[ ! -L "$wavedir/$f" ]]; then
    ln -sf $file $wavedir/$f
  fi
done

#figure out the proper sox command line
#the flac will be converted on the fly

(  for w in `find $wavedir -name *.flac` ; do
    base=`basename $w .flac`
    fullpath=`utils/make_absolute.sh $w`
    echo "$base sox $fullpath -r 16000 -t wav - |"
  done
)  | sort -u > $galeData/wav.scp

#clean
rm -fr $galeData/id$$ $galeData/wav$$
echo "$0: data prep audio succeded"

exit 0

