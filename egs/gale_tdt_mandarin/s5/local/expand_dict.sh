#!/bin/bash

# This script combine the local lexicon with extra lexicon source.
# It adds the most frequent N words from the extra source to the local
# lexicon

thres=100
[ -f path.sh ] && ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 4 ];then
  echo "Usage: $0 [--thres] <local-dict-dir> <extra-dict-dir> <extra-text> <combined-dict-dir>"
  echo "E.g., $0 --thres 1000 data/local/dict data/local/dict_giag GIGA/text data/local/dict_large"
fi

srcdir=$1
extra_dict_dir=$2
extra_text=$3
tgtdir=$4

mkdir -p $tgtdir || exit 1;

for f in lexicon.txt nonsilence_phones.txt silence_phones.txt \
  extra_questions.txt words.txt optional_silence.txt;
do
  cp -r $srcdir/$f $tgtdir || exit 1;
done

# extra_text should not contain any utterance id
cat $extra_text | awk '{for(n=1;n<=NF;n++) print $n; }' | sort | uniq -c | \
  awk -v x=$thres '$1>x' | sort -nr > $tgtdir/extra_word_thres_${thres}.counts || exit 1;

awk 'NR==FNR{a[$1]=$0;next}$1 in a{print a[$1]}' \
  $extra_dict_dir/lexicon.txt $tgtdir/extra_word_thres_${thres}.counts > $tgtdir/lexicon_extra_words.txt

awk '{for (n=2;n<=NF;n++) print $n;}' $tgtdir/lexicon_extra_words.txt | sort -u > $tgtdir/extra_word_phones.txt

awk '{for (n=1;n<=NF;n++) print $n}' $tgtdir/nonsilence_phones.txt |\
  cat - $tgtdir/silence_phones.txt $tgtdir/optional_silence.txt > $tgtdir/full_phones.txt

awk 'NR==FNR{a[$1];next}{if (!($1 in a)) print $0}' $tgtdir/full_phones.txt $tgtdir/extra_word_phones.txt > $tgtdir/extra_word_unknown_phones.txt


num_line=`wc -l $tgtdir/extra_word_unknown_phones.txt | cut -d " " -f1`
if [ $num_line -ne 0 ]; then
  echo "Unseen phones in $tgtdir/extra_word_unknown_phones.txt"
  echo "Check your file $tgtdir/extra_word_phones.txt"
  exit 1;
fi

cat $srcdir/lexicon.txt |\
  grep -v '!SIL' |\
  grep -v '\[LAUGHTER\]' |\
  grep -v '\[NOISE\]' |\
  grep -v '\[VOCALIZEDNOISE\]' |\
  grep -v '\[VOCALIZED-NOISE\]' |\
  grep -v '<UNK>' | \
  cat $tgtdir/lexicon_extra_words.txt - | sort -u > $tgtdir/lexicon_tmp.txt

(echo '!SIL SIL'; echo '[VOCALIZED-NOISE] SPN'; echo '[VOCALIZEDNOISE] SPN';echo '[NOISE] NSN'; echo '[LAUGHTER] LAU';
 echo '<UNK> SPN' ) | \
 cat - $tgtdir/lexicon_tmp.txt  > $tgtdir/lexicon.txt || exit 1;

echo "Expand dictionary succeeded !"
