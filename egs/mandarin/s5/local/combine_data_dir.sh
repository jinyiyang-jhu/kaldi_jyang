#!/bin/bash
gale_dir=data/train_gale
tdt2_3_dir=data/train_tdt2_tdt3_cleanup
tdt4_dir=data/train_tdt4_mandarin
tgt_dir=data/train_cleanup

file_list=(text feats.scp cmvn.scp segments utt2spk spk2utt wav.scp)
for f in "${file_list[@]}"
do
  cat $gale_dir/$f $tdt2_3_dir/$f $tdt4_dir/$f |\
    sort -u > $tgt_dir/$f
done

utils/fix_data_dir.sh $tgt_dir

