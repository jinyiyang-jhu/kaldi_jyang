#!/bin/bash


. path.sh

alidir=$1
latdir=$2

lmwt=17
wip=0.0

phone_table="data/lang/phones.txt"

cmd=run.pl

num_jobs=`ls $alidir/ali.*.gz | wc -l`

if [ ! -d $alidir/phone_ali ];then
    mkdir -p $alidir/phone_ali/log
fi
$cmd nj=1:$num_jobs $alidir/phone_ali/log/get_phone_ali.nj.log \
    ali-to-phones $alidir/final.alimdl ark:"gunzip -c $alidir/ali.nj.gz \|" \
    ark,t:- \| \
    utils/int2sym.pl -f 2- $phone_table \| \
    sed s/_B//g \| sed s/_E//g \| sed s/_I//g \| sed s/_S//g '>' $alidir/phone_ali/ali.nj.phones || exit



#num_jobs=`ls $latdir/lat.1.gz | wc -l`
#hyp_filtering_cmd="cat"
[ -x local/wer_output_filter ] && hyp_filtering_cmd="local/wer_output_filter"
[ -x local/wer_hyp_filter ] && hyp_filtering_cmd="local/wer_hyp_filter"

$cmd nj=1:$num_jobs $latdir/phone_lat/log/get_phone_lat.nj.log \
    lattice-to-phone-lattice $latdir/final.mdl ark:"gunzip -c $latdir/lat.nj.gz\|" \
    ark,t:- \| \
    lattice-scale --inv-acoustic-scale=$lmwt ark:- ark:- \| \
    lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- \| \
    lattice-best-path --word-symbol-table=$phone_table ark:- ark,t:- \| \
    utils/int2sym.pl -f 2- $phone_table \| \
    $hyp_filtering_cmd '>'
