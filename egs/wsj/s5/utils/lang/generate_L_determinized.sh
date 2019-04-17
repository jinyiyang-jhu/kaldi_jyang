#!/bin/bash

python3 utils/lang/make_lexicon_rho_fst.py --sil-prob 0.5 \
    --sil-disambig "#1" --sil-phone "<sil>" \
    --rho-sym "<rho>" --invalid-sym "<oov>" \
    data/lang_nosp_bpe_v3/lexiconp.txt \
    > data/lang_nosp_bpe_v3/L_before_compile.txt
fstcompile --isymbols=data/lang_nosp_bpe_v3/phones.txt \
    --osymbols=data/lang_nosp_bpe_v3/words.txt \
    data/lang_nosp_bpe_v3/L_before_compile.txt \
    > data/lang_nosp_bpe_v3/L.fst
fstdeterminize data/lang_nosp_bpe_v3/L.fst \
    data/lang_nosp_bpe_v3/L_determinized.fst
