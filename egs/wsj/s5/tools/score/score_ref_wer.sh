#!/bin/bash

dir_wrong=$1
dir_correct=$2
result_dir=$3

cut -d " " -f1 $dir_correct/text > $result_dir/utt.id
result_file=$result_dir/wer_ref_wrong_vs_ref_correct.txt
[ -e $result_file ] && rm $result_file
while read -r u; do
    grep $u $dir_wrong/text |\
    compute-wer --text --mode=present ark:$dir_correct/text ark:- \
    > $result_dir/wer_ref_wrong_vs_ref_correct_${u}.txt
    wer_command=`cat $result_dir/wer_ref_wrong_vs_ref_correct_${u}.txt |\
    grep "WER" | cut -d " " -f2`
    echo $u $wer_command >> $result_file
    done < $result_dir/utt.id
    rm $result_dir/wer_ref_wrong_vs_ref_correct_*.txt
    rm $result_dir/utt.id
