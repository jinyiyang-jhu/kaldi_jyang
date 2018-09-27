#!/bin/bash

data=$1
lang=$2
mdldir=$3
alidir=$4
postdir=$5

cmd=run.pl
nj=8
stage=2

if [ ! -d $postdir ]; then
	mkdir -p $postdir
fi

if [ $stage -le 1 ]; then
	steps/nnet2/align.sh --nj $nj $data $lang $mdldir $alidir || exit 1;
fi

#$cmd NJ=1:8 $postdir/log/ali_to_post.NJ.log \
for ((nj=1;nj<=8;++nj))
do
ali-to-post ark:"gunzip -c $alidir/ali.$nj.gz|" ark:- | \
post-to-phone-post $mdldir/final.mdl ark:- ark,t:$postdir/ali.$nj.phone.post
done
