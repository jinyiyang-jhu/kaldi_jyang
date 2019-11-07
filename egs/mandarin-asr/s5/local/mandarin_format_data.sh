#!/bin/bash

# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0

if [ -f path.sh ]; then
  . ./path.sh; else
   echo "missing path.sh"; exit 1;
fi

set -e -o pipefail
set -x

for dir in dev train; do
   cp -prT data/local/$dir data/$dir
   sed -i 's/<TURN>//g' $data/$dir/text
done

export LC_ALL=C

ori_lang=data/lang_with_giga_test
test_lang=data/lang_with_giga_decode
arpa_lm=data/local/lm_4gram/4gram_mincount_ixed_lm.gz
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

rm -r $test_lang || true
cp -r $ori_lang $test_lang

gunzip -c "$arpa_lm" | \
  arpa2fst --disambig-symbol=#0 \
           --read-symbol-table=$test_lang/words.txt - $test_lang/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $test_lang/G.fst || true

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
(
  fstprint   --isymbols=$ori_lang/phones.txt --osymbols=$ori_lang/words.txt $ori_lang/L.fst  | head
) || true
echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize $test_lang/G.fst /dev/null || {
  echo Error determinizing G.
  exit 1
}

# Checking that L_disambig.fst is determinizable.
fstdeterminize $test_lang/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose $test_lang/L_disambig.fst $test_lang/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose $ori_lang/L_disambig.fst $test_lang/G.fst | \
   fstisstochastic || echo LG is not stochastic

echo "Format data succeeded !"

