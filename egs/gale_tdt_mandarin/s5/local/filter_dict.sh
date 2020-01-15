#!/bin/bash

# Copyright 2019 Johns Hopkins University (author: Jinyi Yang)
# This script selects the most frequent words in the text file with a threshold,
# and filter the provided lexicon.txt such that the new lexicon.txt will contain only these words.

thres=100 # Number of occurances of a word
[ -f path.sh ] && ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ];then
  echo "Usage: $0 [--thres] <text-file> <src-dict-dir> <filt-dict-dir>"
  echo "E.g., $0 --thres 1000 data/local/lm/text data/local/dict data/local/dict_filtered"
fi

text=$1
srcdir=$2
tgtdir=$3

mkdir -p $tgtdir || exit 1;

for f in lexicon.txt nonsilence_phones.txt silence_phones.txt \
  extra_questions.txt words.txt optional_silence.txt;
do
  cp -r $srcdir/$f $tgtdir || exit 1;
done

# Note: the text file should not contain utterance ids.
cat $text | awk '{for(n=1;n<=NF;n++) print $n; }' | sort | uniq -c | \
  awk -v x=$thres '$1>x' | sort -nr > $tgtdir/word_thres_${thres}.counts || exit 1;

awk 'NR==FNR{a[$1]=$0;next}$1 in a{print a[$1]}' \
  $tgtdir/word_thres_${thres}.counts $srcdir/lexicon.txt > $tgtdir/lexicon_tmp.txt


(echo '!SIL SIL'; echo '[VOCALIZED-NOISE] SPN'; echo '[VOCALIZEDNOISE] SPN';echo '[NOISE] NSN'; echo '[LAUGHTER] LAU';
 echo '<UNK> SPN' ) | \
 cat - $tgtdir/lexicon_tmp.txt  > $tgtdir/lexicon.txt || exit 1;

rm $tgtdir/lexicon_tmp.txt
echo "Fitering dictionary succeeded !"
