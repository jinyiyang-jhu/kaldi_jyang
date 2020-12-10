#!/bin/bash

# This script prepare data from ESPNET processed corpus
# Note: ESPNET uses " &apos; " for "\'", here we convert it back to "\'"
stage=-1

#espnet_data=/export/fs03/b02/jyang/espnet/egs/fisher_callhome_spanish/st1/data
espnet_data=./espnet_data
output_dir=data
fisher_callhome_speech=data/sph.list
fisher_trans=
callhome_speech=
callhome_trans=
sph2pipe="/export/b07/jyang/kaldi-jyang/kaldi/tools/sph2pipe_v2.5/sph2pipe"
fisher_dsets=("fisher_dev" "fisher_dev" "fisher_dev2" "fisher_test")
callhome_dsets=("callhome_devtest" "callhome_evltest")
src="es"
tgt="en"


if [ $stage -le 0 ]; then
    # Prepare for train
    mkdir -p $output_dir/train || exit 1;
    echo "Preparing the original wav.scp for train set"
    espnet_train_dir=$espnet_data/train_sp.$src

    cut -d "-" -f2- $espnet_train_dir/wav.scp | \
         awk -v sph2pipe=$sph2pipe 'NR==FNR{split($0, f1, "/");
            split(f1[9], tmp, "."); all[tmp[1]]=$0; next};
            {split($1, f2, "-"); if (f2[1] in all){print $1" "sph2pipe" -f wav -p -c "$7" "all[f2[1]] " |"}}' $fisher_callhome_speech - | \
            sort -u > $output_dir/train/wav.scp

    # Select text
    grep "sp1.0" $espnet_train_dir/text.lc.rm | sed "s/ &apos; /'/g" | \
        cut -d "-" -f2- > $output_dir/train/text
    
    # Select utt2spk, spk2utt, utt2num_frames, segments, spk2gender, reco2file_and_channel
    grep "sp1.0" $espnet_train_dir/utt2spk | sed 's/sp1.0-//g' > $output_dir/train/utt2spk
    grep "sp1.0" $espnet_train_dir/spk2utt | sed 's/sp1.0-//g' > $output_dir/train/spk2utt
    grep "sp1.0" $espnet_train_dir/utt2num_frames | sed 's/sp1.0-//g' > $output_dir/train/utt2num_frames
    grep "sp1.0" $espnet_train_dir/segments | sed 's/sp1.0-//g' > $output_dir/train/segments
    grep "sp1.0" $espnet_train_dir/spk2gender | sed 's/sp1.0-//g' > $output_dir/train/spk2gender
    grep "sp1.0" $espnet_train_dir/reco2file_and_channel | sed 's/sp1.0-//g' > $output_dir/train/reco2file_and_channel
fi

if [ $stage -le 2 ]; then
    for dset in "${callhome_dsets[@]}"; do
        echo "Preparing the $dset"
        mkdir -p $output_dir/$dset || exit 1;
        espnet_dset_dir=$espnet_data/${dset}.$src
        # prepare wav.scp
        awk -v sph2pipe=$sph2pipe 'NR==FNR{split($0, f1, "/");
            split(f1[8], tmp, "."); all[tmp[1]]=$0; next};
            {split($1, f2, "-"); if (f2[1] in all){print $1" "sph2pipe" -f wav -p -c "$7" "all[f2[1]] " |"}}' $fisher_callhome_speech $espnet_dset_dir/wav.scp \
            > $output_dir/$dset/wav.scp
        # prepare text
        sed "s/ &apos; /'/g" $espnet_dset_dir/text.lc.rm > $output_dir/$dset/text || exit 1;

        for f in utt2spk spk2utt utt2num_frames segments spk2gender reco2file_and_channel; do
            cp $espnet_dset_dir/$f $output_dir/$dset/$f || exit 1;
        done
    done

    for dset in "${fisher_dsets[@]}"; do
        echo "Preparing the $dset"
        mkdir -p $output_dir/$dset || exit 1;
        espnet_dset_dir=$espnet_data/${dset}.$src
        
        # prepare wav.scp
        awk -v sph2pipe=$sph2pipe 'NR==FNR{split($0, f1, "/");
            split(f1[9], tmp, "."); all[tmp[1]]=$0; next};
            {split($1, f2, "-"); if (f2[1] in all){print $1" "sph2pipe" -f wav -p -c "$7" "all[f2[1]] " |"}}' $fisher_callhome_speech $espnet_dset_dir/wav.scp \
            > $output_dir/$dset/wav.scp
        # prepare text
        sed "s/ &apos; /'/g" $espnet_dset_dir/text.lc.rm > $output_dir/$dset/text || exit 1;

        for f in utt2spk spk2utt utt2num_frames segments spk2gender reco2file_and_channel; do
            cp $espnet_dset_dir/$f $output_dir/$dset/$f || exit 1;
        done
    done
fi



