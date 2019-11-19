#!/bin/bash

# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0

if [ -f path.sh ]; then
  . ./path.sh; else
   echo "missing path.sh"; exit 1;
fi

set -e -o pipefail
set -x

mkdir -p data/gale
for dir in eval dev train; do
   cp -prT data/local/gale/$dir data/gale/$dir
done

export LC_ALL=C

arpa_lm=data/local/gale/train/lm_4gram/srilm.o4g.kn.gz

[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

rm -r data/lang_gale_test || true
cp -r data/lang_gale_tdt data/lang_gale_test

gunzip -c "$arpa_lm" | \
  arpa2fst --disambig-symbol=#0 \
           --read-symbol-table=data/lang_gale_test/words.txt - data/lang_gale_test/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic data/lang_gale_test/G.fst || true

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
(
  fstprint   --isymbols=data/lang_gale_tdt/phones.txt --osymbols=data/lang_gale_tdt/words.txt data/lang_gale_tdt/L.fst | head
) || true
echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize data/lang_gale_test/G.fst /dev/null || {
  echo Error determinizing G.
  exit 1
}

# Checking that L_disambig.fst is determinizable.
fstdeterminize data/lang_gale_test/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose data/lang_gale_test/L_disambig.fst data/lang_gale_test/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose data/lang_gale_tdt/L_disambig.fst data/lang_gale_test/G.fst | \
   fstisstochastic || echo LG is not stochastic


echo gale_format_data  succeeded.
