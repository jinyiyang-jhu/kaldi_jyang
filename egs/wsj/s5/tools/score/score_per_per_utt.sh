#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
decode_mbr=true
word_ins_penalty=0.0
min_lmwt=10
max_lmwt=10
#end configuration section.

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: local/score.sh [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --stage (0|1|2)                 # start scoring script from part-way through."
  echo "    --decode_mbr (true/false)       # maximum bayes risk decoding (confusion network)."
  echo "    --min_lmwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_lmwt <int>                # maximum LM-weight for lattice rescoring "
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3

symtab=$lang_or_graph/words.txt

for f in $symtab $dir/lat.1.gz $data/text_phones_indep; do
  [ ! -f $f ] && echo "score.sh: no such file $f" && exit 1;
done

mkdir -p $dir/scoring/log

cat $data/text_phones_indep | sed 's:NSN::g' | sed 's:SPN::g' > $dir/scoring/test_filt.txt

lmwt=10

if [ ! -f $dir/scoring/$lmwt.tra ]; then
$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/best_path.LMWT.log \
  lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
  lattice-add-penalty --word-ins-penalty=$word_ins_penalty ark:- ark:- \| \
  lattice-best-path --word-symbol-table=$symtab \
    ark:- ark,t:$dir/scoring/LMWT.tra || exit 1;
fi


score_dir=$dir/per_per_utt/
if [ ! -p $score_dir ]; then
	mkdir -p $score_dir
fi

if [ ! -f $score_dir/$lmwt.per ]; then   
    utils/int2sym.pl -f 2- $symtab $dir/scoring/$lmwt.tra | sed 's:NSN::g' | sed 's:SPN::g' | \
    compute-wer-enhance --text --mode=present --utt=yes \
     ark:$dir/scoring/test_filt.txt  ark,p:- > $score_dir/$lmwt.per || exit 1;
fi
exit 0;
