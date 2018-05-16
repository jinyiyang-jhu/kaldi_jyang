#!/bin/bash


if [[ $# -eq 0 ]]; then
    echo "input: database_dir target_dir"
    echo "input should have "text" prepared in format like:"
    echo "basefilename text"
    exit 1
fi

sdir=$1
tdir=$2

if [ ! -e $tdir ]; then
    mkdir $tdir
fi

#tools/data_prep/create_wav_list.pl $sdir

sort -u $sdir/wav.scp > $tdir/wav.scp
sort -u $sdir/text | awk '{s=$2; for (i=3;i<=NF;++i) {s=s" "$i;} print $1" "s}' > $tdir/text

unmatch=`awk 'NR==FNR{a[$1]=1;next} {if(!($1 in a)) print $1}' $tdir/text $tdir/wav.scp | wc -l`
echo $unmatch

if [ $unmatch -ne 0 ]; then
    echo "$tdir/wav.scp and $tdir/text have different utt-id. Exit ..."
    exit 1
fi

paste -d " " <(awk '{print $1}' $tdir/text) <(cut -d "_" -f 1-2 $tdir/text) |\
sort -u > $tdir/utt2spk

utils/utt2spk_to_spk2utt.pl $tdir/utt2spk > $tdir/spk2utt


