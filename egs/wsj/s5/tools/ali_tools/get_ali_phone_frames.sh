#!/bin/bash

. path.sh
. cmd.sh
mdl="exp/tri5a/final.mdl"
alidir="exp/tri5a_dev_20spk_refined_ali"
outdir="exp/tri5a_dev_20spk_refined_ali/ali_phones"

cmd=run.pl
mkdir -p $outdir
nj=`ls $alidir/ali.*.gz | wc -l`
$cmd JOB=1:$nj $outdir/log/ali2phone.JOB.log \
    ali-to-phones --write-lengths $mdl ark:"gunzip -c $alidir/ali.JOB.gz|" \
        ark,t:$outdir/ali_phones.JOB.txt || exit 1;

