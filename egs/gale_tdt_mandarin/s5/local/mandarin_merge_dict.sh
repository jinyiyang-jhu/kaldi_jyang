#!/bin/bash
# This script merges the gale-tdt lexicon dicrectory (with reestimated
# lexiconp.txt) with gigaword (simplified Mandarin) lexicon directory, and
# prune the merged lexiconp.txt file.

if [ $# -ne 3 ];then
  echo "Usage: $0 <lex1-dir> <lex2-dir> <tgt-lex-dir>"
  echo "E.g., $0 data/local/dict_gale data/local/dict_giga data/local/dict_merged"
  exit 1
fi

lex_dir_1=$1
lex_dir_2=$2
tgt_lex_dir=$3

mkdir -p $tgt_lex_dir

for f in silence_phones.txt nonsilence_phones.txt lexiconp.txt extra_questions.txt;do
  [ ! -f $lex_dir_1/$f ] && echo "$0: no such file $lex_dir_1/$f" && exit 1;
  [ ! -f $lex_dir_2/$f ] && echo "$0: no such file $lex_dir_2/$f" && exit 1;
  cp $lex_dir_1/$f $tgt_lex_dir
done

mv $tgt_lex_dir/lexiconp.txt $tgt_lex_dir/lexiconp_1.txt
awk 'NR==FNR{a[$1];next}{if (!($1 in a)) print $0}' $tgt_lex_dir/lexiconp_1.txt \
  $lex_dir_2/lexiconp.txt > $tgt_lex_dir/lexiconp_2.txt
cat $tgt_lex_dir/lexiconp_1.txt $tgt_lex_dir/lexiconp_2.txt | sort > $tgt_lex_dir/lexiconp.txt


