#!/bin/bash

# Copyright 2014 (author: Ahmed Ali, Hainan Xu)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Apache 2.0

if [ $# -ne 2 ]; then
   echo "Arguments should be the <VAST folder> <eval-name>"; exit 1
fi

set -e -o pipefail
#data will data/local


vastData=$(utils/make_absolute.sh $1)
eval_name=$2
mkdir -p data/local
dir=$(utils/make_absolute.sh data/local)


# some problem with the text data; same utt id but different transcription
cat $vastData/all | awk '{print$2}' | \
  sort | uniq -c | awk '{if($1!="1")print$2}' > $vastData/dup.list

utils/filter_scp.pl --exclude -f 2 \
  $vastData/dup.list $vastData/all > $vastData/all.nodup

mv $vastData/all $vastData/all.orig
mv $vastData/all.nodup $vastData/all

# We use VAST only as eval set
cp $vastData/all $vastData/all.eval

cat $vastData/all.eval | awk '{print$2}' > $vastData/eval_utt_list

mkdir -p $dir/$eval_name
eval_dir=$dir/$eval_name
utils/filter_scp.pl -f 1 $vastData/eval_utt_list $vastData/utt2spk > $eval_dir/utt2spk
utils/utt2spk_to_spk2utt.pl $eval_dir/utt2spk | sort -u > $eval_dir/spk2utt


file=$vastData/all.eval
awk '{print $2 " " $1 " " $3 " " $4}' $file  | sort -u > $eval_dir/segments
awk '{printf $2 " "; for (i=5; i<=NF; i++) {printf $i " "} printf "\n"}' $file | sort -u > $eval_dir/text

cat $eval_dir/segments | awk '{print$2}' | sort -u > $vastData/eval.wav.list

utils/filter_scp.pl -f 1 $vastData/eval.wav.list $vastData/wav.scp > $eval_dir/wav.scp


echo data format succeeded
