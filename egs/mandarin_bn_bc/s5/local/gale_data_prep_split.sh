#!/usr/bin/env bash

# Copyright 2014 (author: Ahmed Ali, Hainan Xu)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Copyright 2019 Johns Hopkins Univeersity (author: Jinyi Yang)
# Apache 2.0

if [ $# -ne 2 ]; then
   echo "Arguments should be the <gale folder> <local gale folder>"; exit 1
fi

set -e -o pipefail

mkdir -p $2
galeData=$(utils/make_absolute.sh $1)
dir=$(utils/make_absolute.sh $2)


# some problem with the text data; same utt id but different transcription
cat $galeData/all | awk '{print$2}' | \
  sort | uniq -c | awk '{if($1!="1")print$2}' > $galeData/dup.list

# same time duration but different transcription (multiple speaker speaks at same time)
cat $galeData/all | awk '{print $1" "$3" "$4}' | \
	sort | uniq -c | awk '{if($1!="1")print $2" "$3" "$4}' > $galeData/dup.segment
awk 'NR==FNR{a[$1$2$3];next} $1$3$4 in a {print $2}' $galeData/dup.segment $galeData/all >> $galeData/dup.list

utils/filter_scp.pl --exclude -f 2 \
  $galeData/dup.list $galeData/all > $galeData/all.nodup

if [ ! -f $galeData/all.orig ]; then
  mv $galeData/all $galeData/all.orig
  mv $galeData/all.nodup $galeData/all
fi

#diff <(awk '{print $1}' $galeData/all | sort | uniq) \
#	<(awk '{print $1}' $galeData/wav.scp | sort | uniq) |\
#	 grep '>\|<' | cut -d " " -f2- > $galeData/bad_utts
grep -f <(cat local/gale_dev/test.LDC*) $galeData/all | grep -v -F -f local/gale_bad_utts  > $galeData/all.dev

grep -v -f <(cat local/gale_dev/test.LDC*) $galeData/all |\
  grep -v -f <(cat local/gale_eval/test.LDC*) |\
  grep -v -F -f local/gale_bad_utts  > $galeData/all.train

cat $galeData/all.dev | awk '{print $2}' > $galeData/dev_utt_list
cat $galeData/all.train | awk '{print $2}' > $galeData/train_utt_list

mkdir -p $dir/dev
mkdir -p $dir/train

utils/filter_scp.pl -f 1 $galeData/dev_utt_list $galeData/utt2spk > $dir/dev/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/dev/utt2spk | sort -u > $dir/dev/spk2utt

utils/filter_scp.pl -f 1 $galeData/train_utt_list $galeData/utt2spk > $dir/train/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/train/utt2spk | sort -u > $dir/train/spk2utt

for x in dev train; do
 outdir=$dir/$x
 file=$galeData/all.$x
 awk '{print $2 " " $1 " " $3 " " $4}' $file  | sort -u > $outdir/segments
 awk '{printf $2 " "; for (i=5; i<=NF; i++) {printf $i " "} printf "\n"}' $file | sort -u > $outdir/text
done

cat $dir/dev/segments | awk '{print $2}' | sort -u > $galeData/dev.wav.list
utils/filter_scp.pl -f 1 $galeData/dev.wav.list $galeData/wav.scp > $dir/dev/wav.scp
cat $dir/train/segments | awk '{print $2}' | sort -u > $galeData/train.wav.list
utils/filter_scp.pl -f 1 $galeData/train.wav.list $galeData/wav.scp > $dir/train/wav.scp

cat $galeData/wav.scp | awk -v seg=$dir/train/segments 'BEGIN{while((getline<seg) >0) {seen[$2]=1;}}
 {if (seen[$1]) { print $0}}' > $dir/train/wav.scp


echo Gale data prep split succeeded
