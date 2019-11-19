#!/bin/bash


[ -f ./path.sh ] && . ./path.sh
[ -f ./cmd.sh ] && . ./cmd.sh

train_nj=80
decode_nj=60
stage=3

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
  local/check_oov_rate.sh data/local/dict_gale_tdt/lexicon.txt \
    data/local/gale_tdt_train/text > data/local/gale_tdt_train/oov.rate
  grep "rate" data/local/gale_tdt_train/oov.rate |\
    awk '$10>0{print "Warning: OOV rate is "$10 ", make sure it is a small number"}'
  utils/prepare_lang.sh data/local/dict_gale_tdt "<UNK>" data/local/lang_gale_tdt data/lang_gale_tdt
fi

if [ $stage -le 2 ]; then
  echo "Creating LM for GALE"
  bash local/mandarin_prepare_lm.sh --ngram-order 4 --oov-sym "<UNK>" \
    data/local/dict_gale_tdt data/local/gale/train data/local/gale/train/lm_4gram data/local/gale/dev
  local/gale_format_data.sh
fi

if [ $stage -le 3 ]; then
  echo "Train a GMM-HMM model with part of GALE data for cleaning up model"
  datadir=data/gale
  mfccdir=mfcc/gale
  expdir=exp/gale
  # spread the mfccs over various machines, as this data-set is quite large.
  if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
    mfcc=$(basename $mfccdir) # in case was absolute pathname (unlikely), get basename.
    utils/create_split_dir.pl /export/b{05,06,07,08}/$USER/kaldi-data/egs/gale_asr/s5/$mfcc/storage \
      $mfccdir/storage
  fi
  for x in train dev eval; do
    utils/fix_data_dir.sh $datadir/$x
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $train_nj \
      $datadir/$x exp/make_mfcc/gale/$x $mfccdir
    utils/fix_data_dir.sh $datadir/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh $datadir/$x exp/make_mfcc/gale/$x $mfccdir
  done
  # Let's create a subset with 10k segments to make quick flat-start training:
  utils/subset_data_dir.sh $datadir/train 10000 $datadir/train.10k || exit 1;
  utils/subset_data_dir.sh $datadir/train 50000 $datadir/  train.50k || exit 1;
  utils/subset_data_dir.sh $datadir/train 100000 $datadir/train.100k || exit 1;
  utils/subset_data_dir.sh $datadir/train 200000 $datadir/train.200k || exit 1;

  # Train monophone models on a subset of the data, 10K segment
  # Note: the --boost-silence option should probably be omitted by default
  steps/train_mono.sh --nj $train_nj --cmd "$train_cmd" \
  $datadir/train.10k data/lang_gale_tdt $expdir/mono || exit 1;

  # Get alignments from monophone system.
  steps/align_si.sh --nj $train_nj --cmd "$train_cmd" \
  $datadir/train.50k data/lang_gale_tdt $expdir/mono $expdir/mono_ali.50k || exit 1;

  # Train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \
  2500 30000 $datadir/train.50k data/lang_gale_tdt $expdir/mono_ali.50k $expdir/tri1 || exit 1;
  # Get alignments from tri1 system
steps/align_si.sh --nj $train_nj --cmd "$train_cmd" \
  $datadir/train.100k data/lang_gale_tdt $expdir/tri1
  $expdir/tri1_ali.100k || exit 1;

  # Train tri2a, which is deltas+delta+deltas
  steps/train_deltas.sh --cmd "$train_cmd" \
  3000 40000 $datadir/train.100k data/lang_gale_tdt $expdir/tri1_ali.100k exp/tri2a || exit 1;
  # Get alignments from tri2a system
  steps/align_si.sh --nj $train_nj --cmd "$train_cmd" \
  $datadir/train.200k data/lang_gale_tdt exp/tri2a exp/tri2a_ali.200k || exit 1;
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



