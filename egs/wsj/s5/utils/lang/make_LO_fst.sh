#!/bin/bash

. path.sh
langdir=$1
awk 'NR>=1 && NR<=21217' $langdir/words.txt | \
    python3 utils/lang/make_deduplicate_fst.py --oov-sym "<oov>" \
    > $langdir/O_before_compile.txt

fstcompile --isymbols=$langdir/words.txt --osymbols=$langdir/words.txt \
    $langdir/O_before_compile.txt | fstarcsort > $langdir/O.fst

fstcompose $langdir/L_determinized.fst $langdir/O.fst \
     fstdeterminize > $langdir/LO_determinized.fst
