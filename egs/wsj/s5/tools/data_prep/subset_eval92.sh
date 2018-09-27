#!/bin/bash

srcdir="./data/test_eval92";

suffix=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d");
files=("cmvn.scp" "feats.scp" "spk2gender" "spk2utt" "text" "utt2spk" "wav.scp");


for s in "${suffix[@]}"
do
	tgtdir=${srcdir}_${s}
	if [ ! -d $tgtdir ]; then
		mkdir -p $tgtdir
	fi
	for f in "${files[@]}"
	do
		awk '{ if (substr($1, length($1),1) == var ) print;}' var=$s "$srcdir/$f" > ${srcdir}_${s}/$f
	done
done

