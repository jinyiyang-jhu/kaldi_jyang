#!/bin/bash

wer_one_graph=$1
wer_split_graph=$2
result_dir=$3
wer_detail_one=$4
wer_detail_split=$5

##### Write wer one vs split graphs
if [ $# != 5 ]; then
    echo "Input:"
    echo "one_graph wer summary"
    echo "split_graph wer summary"
    echo "Result dir"
    echo "wer_detail file(split)"
    echo "wer_detail file(one)"
    exit 1;
fi

awk 'NR==FNR{a[$1]=$2;next} $1 in a{print $1,a[$1],$2,a[$1]-$2}' \
    $wer_one_graph $wer_split_graph > $result_dir/wer_one_vs_split.txt

cp $wer_detail_split $result_dir/analysis_split.txt
cp $wer_detail_one $result_dir/analysis_one.txt

## analysis abnormal: one graph wer <= split graph wer
awk '$2<=$3 {print $1}' $result_dir/wer_one_vs_split.txt | \
    grep -f - $wer_detail_split > $result_dir/analysis_abnormal.txt

awk '$2<$3 || $3>0{print $0}' $result_dir/wer_one_vs_split.txt \
    >$result_dir/wer_one_vs_split_abnormal.txt

