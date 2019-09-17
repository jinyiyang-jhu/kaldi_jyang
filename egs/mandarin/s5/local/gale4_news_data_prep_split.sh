#!/bin/bash

# Copyright 2014 (author: Ahmed Ali, Hainan Xu)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Apache 2.0

if [ $# -ne 2 ]; then
   echo "Arguments should be the <gale folder> <tgtdir>"; 
   echo "e.g.: $0 GALE4_news data/local/gale4_news"exit 1
fi

set -e -o pipefail
#data will data/local

galeData=$1
dir=$2
mkdir -p $dir


# some problem with the text data; same utt id but different transcription
cat $galeData/all | sort -u | awk '{print$2}' | \
  sort | uniq -c | awk '{if($1!="1")print$2}' > $galeData/dup.list

utils/filter_scp.pl --exclude -f 2 \
  $galeData/dup.list $galeData/all | sort -u > $galeData/all.nodup

mv $galeData/all $galeData/all.orig
mv $galeData/all.nodup $galeData/all




file=$galeData/all
awk '{print $2 " " $1 " " $3 " " $4}' $file  | sort -u > $dir/segments
awk '{printf $2 " "; for (i=5; i<=NF; i++) {printf $i " "} printf "\n"}' $file | sort -u > $dir/text

awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $dir/text $galeData/utt2spk > $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk | sort -u > $dir/spk2utt

cp $galeData/wav.scp  $dir/wav.scp

cat $galeData/wav.scp | awk -v seg=$dir/segments 'BEGIN{while((getline<seg) >0) {seen[$2]=1;}}
 {if (seen[$1]) { print $0}}' > $dir/wav.scp


echo data prep split succeeded
