#!/bin/bash

# Copyright 2014 (author: Hainan Xu, Ahmed Ali)
# Apache 2.0

. ./path.sh
. ./cmd.sh

num_jobs=80
num_jobs_decode=100
train_dir=data/train_gale
dev_dir=data/dev
lang_dir=data/lang_with_giga
decode_lang=data/lang_with_giga_test
ext="_gale"
# You can run the script from here automatically, but it is recommended to run the data preparation,
# and features extraction manually and and only once.
# By copying and pasting into the shell.

set -e -o pipefail
set -x


# Now make MFCC features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.
mfccdir=mfcc

## spread the mfccs over various machines, as this data-set is quite large.
#if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
#  mfcc=$(basename $mfccdir) # in case was absolute pathname (unlikely), get basename.
#  utils/create_split_dir.pl /export/b{05,06,07,08}/$USER/kaldi-data/egs/gale_mandarin/s5/$mfcc/storage \
#    $mfccdir/storage
#fi


## Let's create a subset with 10k segments to make quick flat-start training:
#utils/subset_data_dir.sh $train_dir 10000 ${train_dir}.10k || exit 1;
#utils/subset_data_dir.sh $train_dir 50000 ${train_dir}.50k || exit 1;
#utils/subset_data_dir.sh $train_dir 100000 ${train_dir}.100k || exit 1;

# Train monophone models on a subset of the data, 10K segment
# Note: the --boost-silence option should probably be omitted by default
#steps/train_mono.sh --nj 40 --cmd "$train_cmd" \
#  ${train_dir}.10k $lang_dir exp/mono$ext || exit 1;

# Get alignments from monophone system.
#steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
#  ${train_dir}.50k $lang_dir exp/mono$ext exp/mono${ext}_ali.50k || exit 1;

# train tri1 [first triphone pass]
#steps/train_deltas.sh --cmd "$train_cmd" \
#  2500 30000 ${train_dir}.50k $lang_dir exp/mono${ext}_ali.50k exp/tri1$ext || exit 1;

# First triphone decoding
utils/mkgraph.sh $decode_lang exp/tri1$ext exp/tri1$ext/graph || exit 1;
steps/decode.sh  --nj $num_jobs_decode --cmd "$decode_cmd" \
  exp/tri1$ext/graph $dev_dir exp/tri1$ext/decode &

steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
  $train_dir $lang_dir exp/tri1$ext exp/tri1${ext}_ali || exit 1;

# Train tri2a, which is deltas+delta+deltas
steps/train_deltas.sh --cmd "$train_cmd" \
  3000 40000 $train_dir $lang_dir exp/tri1${ext}_ali exp/tri2a$ext || exit 1;

# tri2a decoding
utils/mkgraph.sh $decode_lang exp/tri2a$ext exp/tri2a$ext/graph || exit 1;
steps/decode.sh --nj $num_jobs_decode --cmd "$decode_cmd" \
  exp/tri2a$ext/graph $dev_dir exp/tri2a$ext/decode &

steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
  $train_dir $lang_dir exp/tri2a$ext exp/tri2a${ext}_ali || exit 1;

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 4000 50000 \
  $train_dir $lang_dir exp/tri2a${ext}_ali exp/tri2b$ext || exit 1;
utils/mkgraph.sh $decode_lang exp/tri2b$ext exp/tri2b$ext/graph || exit 1;
steps/decode.sh --nj $num_jobs_decode --cmd "$decode_cmd" \
  exp/tri2b$ext/graph $dev_dir exp/tri2b$ext/decode &

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
  --use-graphs true $train_dir $lang_dir exp/tri2b$ext exp/tri2b${ext}_ali  || exit 1;

# From 2b system, train 3b which is LDA + MLLT + SAT.
steps/train_sat.sh --cmd "$train_cmd" \
  5000 100000 $train_dir $lang_dir exp/tri2b${ext}_ali exp/tri3b$ext || exit 1;
utils/mkgraph.sh $decode_lang exp/tri3b$ext exp/tri3b$ext/graph|| exit 1;
steps/decode_fmllr.sh --nj $num_jobs_decode --cmd "$decode_cmd" \
  exp/tri3b$ext/graph $dev_dir exp/tri3b$ext/decode &

# From 3b system, align all data.
steps/align_fmllr.sh --nj $num_jobs --cmd "$train_cmd" \
  $train_dir $lang_dir exp/tri3b$ext exp/tri3b${ext}_ali || exit 1;


echo "# Get WER and CER" > RESULTS
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_[0-9]* | utils/best_wer.sh; \
done | sort -n -r -k2 >> RESULTS
echo "" >> RESULTS
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/cer_[0-9]* | utils/best_wer.sh; \
done | sort -n -r -k2 >> RESULTS

echo training succedded
exit 0
