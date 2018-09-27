#!/bin/bash

dir=$1
cut -d " "  -f2-5 $dir/wav.scp > $dir/wav.tmp
paste -d " " <(cat $dir/wav.tmp) <(awk '{gsub("corpora/LDC/LDC93S1/timit/TIMIT","b07/jyang/kaldi-jyang/kaldi/egs/timit/s5",
$4);print $4}' $dir/wav.tmp) > $dir/wav_cmd.sh
cut -d " " -f5 $dir/wav.tmp > $dir/wavlist
chmod 755 $dir/wav_cmd.sh
while read lines;
do
    mkdir -p "${line%/*}";
done < $dir/wavlist
./$dir/wav_cmd.sh
rm $dir/wav.tmp
