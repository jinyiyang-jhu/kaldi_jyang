#!/bin/bash

nj=30
mdl=exp/tri3/final.mdl
alidir=exp/tri3

. path.sh

for i in `seq $nj`; do
    ali-to-pdf $mdl ark:"gunzip -c $alidir/ali.$i.gz|" ark,t:$alidir/ali.$i.pdfs
done
cat $alidir/ali.*.pdfs > $alidir/train.ali.pdfs
