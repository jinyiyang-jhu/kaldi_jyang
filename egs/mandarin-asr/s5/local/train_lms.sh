#!/bin/bash


# To be run from one directory above this script.
ngram_order=4
oov_sym="<UNK>"
. path.sh
. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: <lm-src-dir> <lm-dir>"
  echo "E.g. $0 --ngram-order 4 <data/local/train> <data/local/lm_no_extra>"
fi

text=$1/text
dir=$2

[ ! -d $dir ] && mkdir -p $dir
[ ! -f $text ] && echo "$0: No such file $text" && exit 1;

lexicon=data/local/dict/lexicon.txt
[ ! -f $lexicon ] && echo "$0: No such file $lexicon" && exit 1;

# check if sri is installed or no
sri_installed=false
which ngram-count  &>/dev/null
if [[ $? == 0 ]]; then
sri_installed=true
fi

# This script takes no arguments.  It assumes you have already run
# previus steps successfully
# It takes as input the files
#data/local/train.*/text
#data/local/dict/lexicon.txt


export LC_ALL=C # You'll get errors about things being not sorted, if you
# have a different locale.
export PATH=$PATH:$KALDI_ROOT/tools/kaldi_lm
( # First make sure the kaldi_lm toolkit is installed.
 cd $KALDI_ROOT/tools || exit 1;
 if [ -d kaldi_lm ]; then
   echo Not installing the kaldi_lm toolkit since it is already there.
 else
   echo Downloading and installing the kaldi_lm tools
   if [ ! -f kaldi_lm.tar.gz ]; then
     wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1;
   fi
   tar -xvzf kaldi_lm.tar.gz || exit 1;
   cd kaldi_lm
   make || exit 1;
   echo Done making the kaldi_lm tools
 fi
) || exit 1;

 cleantext=$dir/text.no_oov

 cat $text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } }
   {for(n=1; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<UNK> ",$n);} } printf("\n");}' \
   > $cleantext || exit 1;


 cat $cleantext | awk '{for(n=2;n<=NF;n++) print $n; }' | sort | uniq -c | \
    sort -nr > $dir/word.counts || exit 1;


# Get counts from acoustic training transcripts, and add  one-count
# for each word in the lexicon (but not silence, we don't want it
# in the LM-- we'll add it optionally later).
 cat $cleantext | awk '{for(n=2;n<=NF;n++) print $n; }' | \
   cat - <(grep -w -v '!SIL' $lexicon | awk '{print $1}') | \
    sort | uniq -c | sort -nr > $dir/unigram.counts || exit 1;

# note: we probably won't really make use of <UNK> as there aren't any OOVs
 cat $dir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<UNK>" > $dir/word_map \
    || exit 1;

# note: ignore 1st field of train.txt, it's the utterance-id.
 cat $cleantext | awk -v wmap=$dir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
   { for(n=2;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print ""; }}}' | gzip -c >$dir/train.gz \
    || exit 1;

 train_lm.sh --arpa --lmtype ${ngram_order}gram-mincount $dir || exit 1;

# note: output is
# $dir/${ngram_order}gram-mincount/lm_unpruned.gz
echo train lm succeeded
