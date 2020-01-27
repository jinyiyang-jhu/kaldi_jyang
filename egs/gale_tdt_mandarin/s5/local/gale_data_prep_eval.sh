#!/bin/bash


eval_src_bc=$1
eval_src_bn=$2
gale_dir=$3

for affix in bc bn ; do
  dir="eval_src_${affix}"
  find -L ${!dir} -type f -name *.qrtr.tdf |\
    while read file; do
      sed '1,3d' $file | awk '{printf "%s %0.3f %0.3f\n", $1,$3,$4}'
    done > $gale_dir/eval_${affix}.segment
  awk '{print $1}' $gale_dir/eval_${affix}.segment |\
    sort -u > $gale_dir/eval_${affix}.wav.list
done



