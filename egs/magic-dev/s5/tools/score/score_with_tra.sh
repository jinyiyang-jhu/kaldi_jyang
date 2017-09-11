#!/bin/bash

min_lmwt=$1
max_lmwt=$2
dir=$3
symtab=$4
trans=$5

for k in `seq $min_lmwt $max_lmwt`; do
	echo $k
	cat $dir/scoring/$k.tra | utils/int2sym.pl -f 2- $symtab | compute-wer --text --mode=present ark:$trans ark:-  || exit 1;
done

