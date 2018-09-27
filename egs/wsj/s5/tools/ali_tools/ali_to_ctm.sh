#!/bin/bash

. path.sh

alidir="./exp/tri2b_ali_si284"
table="data/lang_nosp/phones.txt"


for i in $alidir/ali.*.gz;do
    n=`echo $i | grep -o -P '(?<=ali\.).*(?=.gz)'`
    echo $n
    gunzip -c $i | ali-to-phones --per-frame $alidir/final.mdl ark:- ark,t: | \
        int2sym.pl -f 2- $table > $alidir/ali.$n.txt
done
