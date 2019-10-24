#!/bin/bash


chain_model="false"
cmd="run.pl"
stage=0
nj=

[ -f path.sh ] && . ./path.sh
. parse_options.sh || exit 1;
. cmd.sh

if [ $# -ne 4 ];then
    echo "Usage: $0 [ --chain-model true | false] <lang> <align-dir> <decode-dir> <result-dir>"
    exit 1
fi
lang=$1
align_dir=$2
decode_dir=$3
result_dir=$4

decode_mdl="$(dirname $decode_dir)/final.mdl"
[ ! -f $decode_dir/lat.1.gz ] && echo "Decoding lattice does not exist !" && exit 1;
[ -d $result_dir ] || mkdir -p $result_dir || exit 1;

# Chain model lattice has 3 times shift
if [ $chain_model == "true"  ]; then
  chain_model="--chain_model"
  echo "Using chain model lattice"
else
  chain_model=""
fi

nj=`ls $decode_dir/lat.*.gz | wc -l`
if [ `ls $align_dir/lat.*.gz | wc -l` -ne $nj ]; then
    echo "Align does not exist, or align.*.gz number not equal to lat.*.gz, first run steps/align_fmllr_lats.sh with --nj $nj"
    echo "e.g. steps/align_fmllr_lats.sh --nj $lat_nj <data-dir> <lang> <align-mdl-dir> <align-lat-dir>"
    exit 1;
fi

postdir_ref=$result_dir/post_ref
postdir_hyp=$result_dir/post_hyp

ali_nj=`ls $align_dir/lat.*.gz | wc -l`
if [ $ali_nj != $nj ]; then
  echo "Number of align lattices do not equal to decoding lattices !"
  exit 1;
fi

if [ $stage -le 1 ]; then
  echo "Computing posterior from alignment"
  $cmd JOB=1:$nj $postdir_ref/log/align-post.JOB.log \
    lattice-1best "ark:gunzip -c $align_dir/lat.JOB.gz|" ark:- \| \
    lattice-align-words $lang/phones/word_boundary.int $align_dir/final.mdl ark:- ark:- \| \
    lattice-arc-post $align_dir/final.mdl ark:- $postdir_ref/post.JOB.txt || exit 1;
fi

if [ $stage -le 2 ]; then
  echo "Computing posterior from lattice"
  $cmd JOB=1:$nj $postdir_hyp/log/lattice-post.JOB.log \
    lattice-align-words $lang/phones/word_boundary.int $decode_mdl "ark:gunzip -c $decode_dir/lat.JOB.gz |" ark:- \| \
    lattice-arc-post $decode_mdl ark:- $postdir_hyp/post.JOB.txt || exit 1;
fi

if [ $stage -le 3 ]; then
  echo "Computing auc score"
  $cmd JOB=1:$nj $result_dir/log/score-auc.JOB.log \
    python3 utils/auc/compute_auc.py \
      $chain_model \
      "$postdir_ref/post.JOB.txt" \
      "$postdir_hyp/post.JOB.txt" \
      "$result_dir/auc_scores.JOB.txt" || exit 1;
  cat $result_dir/auc_scores.*.txt > $result_dir/auc_scores.txt
  rm $result_dir/auc_scores.*.txt
fi

python3 utils/auc/plot_auc.py $result_dir/auc_scores.txt $result_dir/auc.png
