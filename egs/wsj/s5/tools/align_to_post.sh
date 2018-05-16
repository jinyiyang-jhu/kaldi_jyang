#!/bin/bash

data=$1
lang=$2
mdldir=$3
alidir=$4
postdir=$5

nj=1
stage=1

if [ ! -d $postdir ]; then
	mkdir -p $postdir
fi

if [ $stage -le 1 ]; then
	steps/nnet2/align.sh --nj $nj $data $lang $mdldir $alidir || exit 1;
fi

ali-to-post ark:"gunzip -c $alidir/ali.$nj.gz|" ark:- | \
	post-to-phone-post $mdldir/final.mdl ark:- ark,t:$postdir/ali.$nj.phone.post
