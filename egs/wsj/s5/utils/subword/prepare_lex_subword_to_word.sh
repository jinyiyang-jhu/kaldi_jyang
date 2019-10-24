#!/bin/bash


oov_sym="<UNK>"

. path.sh
. parse_options.sh 
if [ $# != 4 ]; then
  echo "Usage: $0 [--oov-sym]<word-list> <subword-list> <pair-code> <subword-lang-tmp-dir>"
    echo "E.g. $0 --oov-sym=<UNK> data/lang_word/words.txt data/lang_subword/words.txt"
    echo "data/lang_subword/pair_code.txt data/lang_subword_to_word"
  exit 1;
fi

words=$1
subwords=$2
pair_code=$3
tmpdir=$4

mkdir -p $tmpdir
#cut -d " " -f1 $words | grep -vw '<eps>\|#[0-9]\|<s>\|</s>' > $tmpdir/words.list
## First, create a mapping between word to subword
#utils/subword/make_word_to_subword_lexicon.sh \
#  $tmpdir/words.list $pair_code $tmpdir/lexicon_words_to_subwords.txt


#echo $'<s> <s>\n</s> </s>' >> $tmpdir/lexicon_words_to_subwords.txt
#sed -i '1i <eps>\t<eps>' $tmpdir/lexicon_words_to_subwords.txt

awk 'NR==FNR{a[$1]=$2;next}{str=$1;for (i=2;i<=NF;++i){str=str" "a[$i];} print
str}' $subwords $tmpdir/lexicon_words_to_subwords.txt \
  > $tmpdir/lexicon_words_to_subwords.int.tmp

awk 'NR==FNR{a[$1]=$2;next}{str=a[$1];for (i=2;i<=NF;++i){str=str" "$i;} print str}' $words $tmpdir/lexicon_words_to_subwords.int.tmp \
  > $tmpdir/lexicon_words_to_subwords.int
rm $tmpdir/lexicon_words_to_subwords.int.tmp

oov_int=`grep -w $oov_sym $words | cut -d " " -f2`
awk '{print $NF}' $tmpdir/lexicon_words_to_subwords.txt | sort -u > $tmpdir/stops.txt
awk 'NR==FNR{a[$1]=$2;next}{print a[$1]}' $subwords $tmpdir/stops.txt > $tmpdir/stops.int





