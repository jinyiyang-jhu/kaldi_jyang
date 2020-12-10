#!/usr/bin/env bash
#
# Copyright 2018  Nagendra Goel, Saikiran Valluri  Apache 2.0
# Copyright 2014  Gaurav Kumar.   Apache 2.0
# Recipe for Fisher/Callhome-Spanish

stage=0
train_stage=-20
train_sgmm2=false

# call the next line with the directory where the Spanish Fisher data is
# (the values below are just an example).
#sfisher_speech=/export/corpora5/LDC/LDC2010S01
#sfisher_transcripts=/export/corpora5/LDC/LDC2010T04
#spanish_lexicon=/export/corpora5/LDC/LDC96L16
split=local/splits/split_fisher
#callhome_speech=/export/corpora5/LDC/LDC96S35
#callhome_transcripts=/export/corpora5/LDC/LDC96T17
split_callhome=local/splits/split_callhome

dsets=("train" "fisher_dev" "fisher_dev2" "fisher_test" "callhome_devtest" "callhome_evltest")
eval_sets=("fisher_dev" "fisher_dev2" "fisher_test" "callhome_devtest" "callhome_evltest")

mfccdir=`pwd`/mfcc

. ./cmd.sh
if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

set -e

if [ $stage -le 0 ]; then
  #local/fsp_data_prep.sh $sfisher_speech $sfisher_transcripts

  # local/callhome_data_prep.sh $callhome_speech $callhome_transcripts

  # Prepare the data from ESPNET provided dataset
  local/prepare_data_from_espnet/prepare_data.sh
  # The lexicon is created using the LDC spanish lexicon, the words from the
  # fisher spanish corpus. Additional (most frequent) words are added from the
  # ES gigaword corpus to bring the total to 64k words. The ES frequency sorted
  # wordlist is downloaded if it is not available.
  local/fsp_prepare_dict.sh data/train $spanish_lexicon
  

  # Added c,j, v to the non silences phones manually
  utils/prepare_lang.sh data/local/dict "<unk>" data/local/lang data/lang

  # Make sure that you do not use your test and your dev sets to train the LM
  # Some form of cross validation is possible where you decode your dev/set based on an
  # LM that is trained on  everything but that that conversation
  # When in doubt about what your data partitions should be use local/fsp_ideal_data_partitions.pl
  # to get the numbers. Depending on your needs, you might have to change the size of
  # the splits within that file. The default paritions are based on the Kaldi + Joshua
  # requirements which means that I have very large dev and test sets
  local/fsp_train_lms.sh $split data/train
  local/fsp_create_test_lang.sh
fi

if [ $stage -le 1 ]; then
    echo "Making MFCC for train"
    steps/make_mfcc.sh --nj 80 --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir || exit 1;
    
    for dset in "${eval_sets[@]}"; do
      echo "Making MFCC for $dset"
      steps/make_mfcc.sh --nj 40 --cmd "$train_cmd" data/$dset exp/make_mfcc/$dset $mfccdir || exit 1;
    done

    for dset in "${dsets[@]}"; do
      utils/fix_data_dir.sh data/$dset
      utils/validate_data_dir.sh data/$dset
      steps/compute_cmvn_stats.sh data/$dset exp/make_mfcc/$dset $mfccdir || exit 1;
    done
fi

if [ $stage -le 2 ]; then
  # Again from Dan's recipe : Reduced monophone training data
  # Now-- there are 1.6 million utterances, and we want to start the monophone training
  # on relatively short utterances (easier to align), but not only the very shortest
  # ones (mostly uh-huh).  So take the 100k shortest ones, and then take 10k random
  # utterances from those.

  utils/subset_data_dir.sh --shortest data/train 90000 data/train_100kshort
  utils/subset_data_dir.sh  data/train_100kshort 10000 data/train_10k
  utils/data/remove_dup_utts.sh 100 data/train_10k data/train_10k_nodup
  utils/subset_data_dir.sh --speakers data/train 30000 data/train_30k
  utils/subset_data_dir.sh --speakers data/train 90000 data/train_100k
fi

if [ $stage -le 3 ]; then
  steps/train_mono.sh --nj 10 --cmd "$train_cmd" \
    data/train_10k_nodup data/lang exp/mono0a

  steps/align_si.sh --nj 30 --cmd "$train_cmd" \
    data/train_30k data/lang exp/mono0a exp/mono0a_ali || exit 1;

  steps/train_deltas.sh --cmd "$train_cmd" \
    2500 20000 data/train_30k data/lang exp/mono0a_ali exp/tri1 || exit 1;


  (utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph
  steps/decode.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
    exp/tri1/graph data/dev exp/tri1/decode_dev)&

  steps/align_si.sh --nj 30 --cmd "$train_cmd" \
    data/train_30k data/lang exp/tri1 exp/tri1_ali || exit 1;

  steps/train_deltas.sh --cmd "$train_cmd" \
    2500 20000 data/train_30k data/lang exp/tri1_ali exp/tri2 || exit 1;

  (
    utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph || exit 1;
    steps/decode.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri2/graph data/dev exp/tri2/decode_dev || exit 1;
   )&
fi

if [ $stage -le 4 ]; then
  steps/align_si.sh --nj 30 --cmd "$train_cmd" \
    data/train_100k data/lang exp/tri2 exp/tri2_ali || exit 1;

# Train tri3a, which is LDA+MLLT, on 100k data.
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" \
   3000 40000 data/train_100k data/lang exp/tri2_ali exp/tri3a || exit 1;
  (
    utils/mkgraph.sh data/lang_test exp/tri3a exp/tri3a/graph || exit 1;
    steps/decode.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
     exp/tri3a/graph data/dev exp/tri3a/decode_dev || exit 1;
  )&
fi

if [ $stage -le 5 ]; then
# Next we'll use fMLLR and train with SAT (i.e. on
# fMLLR features)
  steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
    data/train_100k data/lang exp/tri3a exp/tri3a_ali || exit 1;

  steps/train_sat.sh  --cmd "$train_cmd" \
    4000 60000 data/train_100k data/lang exp/tri3a_ali  exp/tri4a || exit 1;

  (
    utils/mkgraph.sh data/lang_test exp/tri4a exp/tri4a/graph
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri4a/graph data/dev exp/tri4a/decode_dev
)&


  steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
    data/train data/lang exp/tri4a exp/tri4a_ali || exit 1;

# Reduce the number of gaussians
  steps/train_sat.sh  --cmd "$train_cmd" \
    5000 120000 data/train data/lang exp/tri4a_ali  exp/tri5a || exit 1;

  (
    utils/mkgraph.sh data/lang_test exp/tri5a exp/tri5a/graph
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri5a/graph data/dev exp/tri5a/decode_dev
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri5a/graph data/test exp/tri5a/decode_test

  # Decode CALLHOME
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri5a/graph data/callhome_test exp/tri5a/decode_callhome_test
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri5a/graph data/callhome_dev exp/tri5a/decode_callhome_dev
    steps/decode_fmllr.sh --nj 25 --cmd "$decode_cmd" --config conf/decode.config \
      exp/tri5a/graph data/callhome_train exp/tri5a/decode_callhome_train
    ) &


   steps/align_fmllr.sh \
     --boost-silence 0.5 --nj 32 --cmd "$train_cmd" \
     data/train data/lang exp/tri5a exp/tri5a_ali
fi

if $train_sgmm2; then

steps/train_ubm.sh \
  --cmd "$train_cmd" 750 \
  data/train data/lang exp/tri5a_ali exp/ubm5

steps/train_sgmm2.sh \
  --cmd "$train_cmd" 5000 18000 \
  data/train data/lang exp/tri5a_ali exp/ubm5/final.ubm exp/sgmm5

utils/mkgraph.sh data/lang_test exp/sgmm5 exp/sgmm5/graph

(
  steps/decode_sgmm2.sh --nj 13 --cmd "$decode_cmd" --num-threads 5 \
    --config conf/decode.config  --scoring-opts "--min-lmwt 8 --max-lmwt 16" --transform-dir exp/tri5a/decode_dev \
   exp/sgmm5/graph data/dev exp/sgmm5/decode_dev
)&

steps/align_sgmm2.sh \
  --nj 32  --cmd "$train_cmd" --transform-dir exp/tri5a_ali \
  --use-graphs true --use-gselect true \
  data/train data/lang exp/sgmm5 exp/sgmm5_ali

steps/make_denlats_sgmm2.sh \
  --nj 32 --sub-split 32 --num-threads 4 \
  --beam 10.0 --lattice-beam 6 --cmd "$decode_cmd" --transform-dir exp/tri5a_ali \
  data/train data/lang exp/sgmm5_ali exp/sgmm5_denlats

steps/train_mmi_sgmm2.sh \
  --cmd "$train_cmd" --drop-frames true --transform-dir exp/tri5a_ali --boost 0.1 \
  data/train data/lang exp/sgmm5_ali exp/sgmm5_denlats \
  exp/sgmm5_mmi_b0.1

(
utils/mkgraph.sh data/lang_test exp/tri5a exp/tri5a/graph
steps/decode_fmllr_extra.sh --nj 13 --cmd "$decode_cmd" --num-threads 4 --parallel-opts " -pe smp 4" \
  --config conf/decode.config  --scoring-opts "--min-lmwt 8 --max-lmwt 12"\
 exp/tri5a/graph data/dev exp/tri5a/decode_dev
utils/mkgraph.sh data/lang_test exp/sgmm5 exp/sgmm5/graph
steps/decode_sgmm2.sh --nj 13 --cmd "$decode_cmd" --num-threads 5 \
  --config conf/decode.config  --scoring-opts "--min-lmwt 8 --max-lmwt 16" --transform-dir exp/tri5a/decode_dev \
 exp/sgmm5/graph data/dev exp/sgmm5/decode_dev
for iter in 1 2 3 4; do
  decode=exp/sgmm5_mmi_b0.1/decode_dev_it$iter
  mkdir -p $decode
  steps/decode_sgmm2_rescore.sh  \
    --cmd "$decode_cmd" --iter $iter --transform-dir exp/tri5a/decode_dev \
    data/lang_test data/dev/  exp/sgmm5/decode_dev $decode
done
) &

fi

local/chain/run_tdnn_1g.sh --stage $stage --train-stage $train_stage || exit 1;
exit 0;
