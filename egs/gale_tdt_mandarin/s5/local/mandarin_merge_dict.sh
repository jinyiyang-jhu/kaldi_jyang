#!/bin/bash

if [ $# -ne 3 ];then
  echo "Usage: $0 <lex-dir-1> <lex-dir-2> <tgt-lex-dir>"
  echo "E.g., $0 data/local/dict_gale data/local/dict_tdt data/local/dict_gale_tdt"
  exit 1
fi

lex_dir_1=$1
lex_dir_2=$2
tgt_lex_dir=$3

for f in silence_phones.txt nonsilence_phones.txt lexicon.txt
  extra_questions.txt
