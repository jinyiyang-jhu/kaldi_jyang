#!/bin/bash

# Copyright 2014 (author: Ahmed Ali, Hainan Xu)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Copyright 2019 Johns Hopkins Univeersity (author: Jinyi Yang)
# Apache 2.0

if [ $# -ne 2 ]; then
   echo "Arguments should be the <gale folder> <local gale folder>"; exit 1
fi

set -e -o pipefail
galeData=$1
dir=$2
mkdir -p $dir
# some problem with the text data; same utt id but different transcription
cat $galeData/all | awk '{print$2}' | \
  sort | uniq -c | awk '{if($1!="1")print$2}' > $galeData/dup.list

# same time duration but different transcription (multiple speaker speaks at same time)
cat $galeData/all | awk '{print $1" "$3" "$4}' | \
	sort | uniq -c | awk '{if($1!="1")print $2" "$3" "$4}' > $galeData/dup.segment
awk 'NR==FNR{a[$1$2$3];next} $1$3$4 in a {print $2}' $galeData/dup.segment $galeData/all >> $galeData/dup.list

utils/filter_scp.pl --exclude -f 2 \
  $galeData/dup.list $galeData/all > $galeData/all.nodup

echo "Finding bad utts"
diff <(awk '{print $1}' $galeData/all.nodup | sort | uniq) \
  <(awk '{print $1}' $galeData/wav.scp | sort | uniq) |\
  grep '>\|<' | cut -d " " -f2- > $galeData/bad_utts || echo "no diff"

echo "Filtering"
cat $galeData/all.nodup | grep -v -F -f $galeData/bad_utts  > $galeData/all.filtered

cat $galeData/all.filtered | awk '{print$2}' > $galeData/utt_list

echo "Utt2spk"
utils/filter_scp.pl -f 1 $galeData/utt_list $galeData/utt2spk > $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk | sort -u > $dir/spk2utt


file=$galeData/all.filtered
awk '{print $2 " " $1 " " $3 " " $4}' $file  | sort -u > $dir/segments
awk '{printf $2 " "; for (i=5; i<=NF; i++) {printf $i " "} printf "\n"}' $file | sort -u > $dir/text

cat $dir/segments | awk '{print$2}' | sort -u > $galeData/wav.list

utils/filter_scp.pl -f 1 $galeData/wav.list $galeData/wav.scp > $dir/wav.scp

echo Gale data prep split succeeded
