#!/bin/bash


. path.sh
. cmd.sh

num_jobs=64
num_decode_jobs=40
stage=1

GALE_AUDIO=(
  /export/corpora/LDC/LDC2013S08/
  /export/corpora/LDC/LDC2013S04/
  /export/corpora/LDC/LDC2014S09/
  /export/corpora/LDC/LDC2015S06/
  /export/corpora/LDC/LDC2015S13/
  /export/corpora/LDC/LDC2016S03/
  /export/corpora/LDC/LDC2017S25/
)
GALE_TEXT=(
  /export/corpora/LDC/LDC2013T20/
  /export/corpora/LDC/LDC2013T08/
  /export/corpora/LDC/LDC2014T28/
  /export/corpora/LDC/LDC2015T09/
  /export/corpora/LDC/LDC2015T25/
  /export/corpora/LDC/LDC2016T12/
  /export/corpora/LDC/LDC2017T18/
)

TDT_AUDIO=(
  /export/corpora/LDC/LDC2001S93/
  /export/corpora/LDC/LDC2001S95/
  /export/corpora/LDC/LDC2005S11/
)
TDT_TEXT=(
  /export/corpora/LDC/LDC2001T57/
  /export/corpora/LDC/LDC2001T58/
  /export/corpora5/LDC/LDC2005T16/
)

GIGA_TEXT=/export/

galeData=GALE/
tdtData=TDT/

set -e -o pipefail
set -x

if [ $stage -le 0 ]; then
  echo "Prepare data for GALE"
  local/gale_data_prep_audio.sh "${GALE_AUDIO[@]}" $galeData
  local/gale_data_prep_txt.sh  "${GALE_TEXT[@]}" $galeData
  local/gale_data_prep_split.sh $galeData data/local/gale

  echo "Prepare data for TDT"
  local/tdt_mandarin_data_prep_audio.sh "${TDT_AUDIO[@]}" $tdtData
  local/tdt_mandarin_data_prep_txt.sh  "${TDT_TEXT[@]}" $tdtData
  local/tdt_mandarin_data_prep_filter.sh $tdtData data/local/tdt_mandarin

  # Merge transcripts from GALE and TDT for lexicon and LM training
  mkdir -p data/local/gale_tdt_train
  cat data/local/gale/train/text data/local/tdt_mandarin/text > data/local/gale_tdt_train/text
fi

if [ $stage -le 1 ]; then
  echo "Prepare dictionary for GALE and TDT"
  local/mandarin_prepare_dict.sh data/local/dict_gale_tdt data/local/gale_tdt_train
fi

if [ $stage -le 2 ]; then
  echo "Creating LM for GALE"
  local/mandarin_prepare_lm.sh --ngram-order 4 --oov-sym "<UNK>" \
    data/local/dict_gale_tdt data/local/gale/train data/local/gale/train/\lm data/local/gale/dev
fi

if [ $stage -le 3 ]; then
  echo "Train a GMM-HMM model with part of GALE data for cleaning up model"
fi

if [ $stage -le 4 ]; then
  echo "Clean up TDT data"
fi

if [ $stage -le 5 ]; then
  echo "Expand the lexicon with Gigaword"
  local/gigaword_prepare.sh $GIGA_TEXT
  local/mandarin_prepare_dict.sh data/local/dict_giga_man_simp data/local/giga_man_simp
  local/mandarin_merge_dict.sh data/local/dict_gale_tdt data/local/dict_giga_man_simp data/local/dict_gale_tdt_giga
fi


if [ $stage -le 5 ]; then
  echo "Prepare LM with all data"
  local/mandarin_prepare_lm.sh --ngram-order 4 --oov-sym "<UNK>" \
  data/train_cleanup 



