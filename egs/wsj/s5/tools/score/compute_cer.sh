#!/bin/bash


. path.sh

if [ $# -ne 4 ];then
    echo "$0: ref hyp cer_file cer_file_details"
fi
ref=$1
hyp=$2
details=$4
cer_file=$3
#compute-wer --text --mode=present ark:$ref ark:$hyp ">&" $result || exit

align-text --special-symbol="'***'" ark:$ref ark:$hyp ark,t:-| \
    utils/scoring/wer_per_utt_details.pl --special-symbol "'***'" > $details

python3 ./tools/score/wer_details_to_wer.py $details $cer_file
