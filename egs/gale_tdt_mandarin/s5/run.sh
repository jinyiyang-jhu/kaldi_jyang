#!/bin/bash




train_nj=80
decode_nj=60
stage=3

[ -f ./path.sh ] && . ./path.sh
[ -f ./cmd.sh ] && . ./cmd.sh
. parse_options.sh

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

GIGA_TEXT=/export/corpora/LDC/LDC2003T09/gigaword_man/xin/

galeData=GALE/
tdtData=TDT/
gigaData=GIGA/

set -e -o pipefail
set -x

########################### Data preparation ###########################
if [ $stage -le 0 ]; then
  echo "`date -u`: Prepare data for GALE"
  local/gale_data_prep_audio.sh "${GALE_AUDIO[@]}" $galeData
  local/gale_data_prep_txt.sh  "${GALE_TEXT[@]}" $galeData
  local/gale_data_prep_split.sh $galeData data/local/gale

  echo "`date -u`: Prepare data for TDT"
  local/tdt_mandarin_data_prep_audio.sh "${TDT_AUDIO[@]}" $tdtData
  local/tdt_mandarin_data_prep_txt.sh  "${TDT_TEXT[@]}" $tdtData
  local/tdt_mandarin_data_prep_filter.sh $tdtData data/local/tdt_mandarin

  # Merge transcripts from GALE and TDT for lexicon and LM training
  mkdir -p data/local/gale_tdt_train
  cat data/local/gale/train/text data/local/tdt_mandarin/text > data/local/gale_tdt_train/text
fi

########################### Lexicon preparation ########################
if [ $stage -le 1 ]; then
  echo "`date -u`: Prepare dictionary for GALE and TDT"
  local/mandarin_prepare_dict.sh data/local/dict_gale_tdt data/local/gale_tdt_train
  local/check_oov_rate.sh data/local/dict_gale_tdt/lexicon.txt \
    data/local/gale_tdt_train/text > data/local/gale_tdt_train/oov.rate
  grep "rate" data/local/gale_tdt_train/oov.rate |\
    awk '$10>0{print "Warning: OOV rate is "$10 ", make sure it is a small number"}'
  utils/prepare_lang.sh data/local/dict_gale_tdt "<UNK>" data/local/lang_gale_tdt data/lang_gale_tdt
fi

########################### LM preparation for GALE ####################
if [ $stage -le 2 ]; then
  echo "`date -u`: Creating LM for GALE"
  bash local/mandarin_prepare_lm.sh --no-uttid "false" --ngram-order 4 --oov-sym "<UNK>" \
    data/local/dict_gale_tdt data/local/gale/train data/local/gale/train/lm_4gram data/local/gale/dev
  local/gale_format_data.sh
fi

############# Using GALE data to train cleaning up model for TDT #######
datadir=data/gale
mfccdir=mfcc/gale
expdir=exp/gale
if [ $stage -le 3 ]; then
  # spread the mfccs over various machines, as this data-set is quite large.
  if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
    mfcc=$(basename $mfccdir) # in case was absolute pathname (unlikely), get basename.
    utils/create_split_dir.pl /export/b{05,06,07,08}/$USER/kaldi-data/egs/gale_asr/s5/$mfcc/storage \
      $mfccdir/storage
  fi
  echo "`date -u`: Extracting GALE MFCC features"
  for x in train dev eval; do
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $train_nj \
      $datadir/$x exp/make_mfcc/gale/$x $mfccdir
    utils/fix_data_dir.sh $datadir/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh $datadir/$x exp/make_mfcc/gale/$x $mfccdir
  done
# Let's create small subsets to make quick flat-start training:
# train_100k contains about 150 hours of data.
	utils/subset_data_dir.sh $datadir/train 100000 $datadir/train_100k || exit 1;
	utils/subset_data_dir.sh --shortest $datadir/train_100k 2000 $datadir/train_2k_short || exit 1;
	utils/subset_data_dir.sh $datadir/train_100k 5000 $datadir/train_5k || exit 1;
	utils/subset_data_dir.sh $datadir/train_100k 10000 $datadir/train_10k || exit 1;
fi

########################### Monophone training #########################
if [ $stage -le 4 ]; then
  echo "`date -u`: Monophone trainign with GALE data"
	steps/train_mono.sh --boost-silence 1.25 --nj $train_nj --cmd "$train_cmd" \
  $datadir/train_2k_short data/lang_gale_tdt $expdir/mono || exit 1;
fi

########################### Tri1 training ##############################
if [ $stage -le 5 ]; then
  steps/align_si.sh --boost-silence 1.25 --nj $train_nj --cmd "$train_cmd" \
    $datadir/train_5k data/lang_gale_tdt $expdir/mono $expdir/mono_ali_5k || exit 1;
  echo "`date -u`: Tri1 trainign with GALE data"
	# train tri1 [first triphone pass]
	steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
  	2000 10000 $datadir/train_5k data/lang_gale_tdt $expdir/mono_ali_5k $expdir/tri1 || exit 1;
	utils/mkgraph.sh data/lang_gale_test $expdir/tri1 $expdir/tri1/graph_gale_test || exit 1;
	steps/decode.sh  --nj $decode_nj --cmd "$decode_cmd" \
  	$expdir/tri1/graph_gale_test $datadir/eval $expdir/tri1/decode_gale_eval
fi

########################### Tri2b training ##############################
if [ $stage -le 6 ]; then
	steps/align_si.sh --nj $train_nj --cmd "$train_cmd" \
  	$datadir/train_10k data/lang_gale_tdt $expdir/tri1 $expdir/tri1_ali_10k || exit 1;
  echo "`date -u`: Tri2b trainign with GALE data"
	steps/train_lda_mllt.sh --cmd "$train_cmd" \
                          --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
                          $datadir/train_10k data/lang_gale_tdt $expdir/tri1_ali_10k $expdir/tri2b
	utils/mkgraph.sh data/lang_gale_test $expdir/tri2b $expdir/tri2b/graph_gale_test || exit 1;
	steps/decode.sh  --nj $decode_nj --cmd "$decode_cmd" \
  	$expdir/tri2b/graph_gale_test $datadir/eval $expdir/tri2b/decode_gale_eval
fi

########################### Tri3b training ##############################
if [ $stage -le 7 ]; then
	steps/align_si.sh --nj $train_nj --cmd "$train_cmd" --use-graphs true \
  	$datadir/train_10k data/lang_gale_tdt $expdir/tri2b $expdir/tri2b_ali_10k || exit 1;
  echo "`date -u`: Tri3b trainign with GALE data"
	steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
                     $datadir/train_10k data/lang_gale_tdt $expdir/tri2b_ali_10k exp/tri3b
	utils/mkgraph.sh data/lang_gale_test $expdir/tri3b $expdir/tri3b/graph_gale_test || exit 1;
	steps/decodei_fmllr.sh  --nj $decode_nj --cmd "$decode_cmd" \
  	$expdir/tri3b/graph_gale_test $datadir/eval $expdir/tri3b/decode_gale_eval
fi

########################### Tri4b training ##############################
if [ $stage -le 8 ]; then
	steps/align_fmllr.sh --nj $train_nj --cmd "$train_cmd" \
    $datadir/train_100k data/lang_gale_tdt \
    $expdir/tri3b $expdir/tri3b_ali_100k || exit 1;
  echo "`date -u`: Tri4b trainign with GALE data"
	steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
                      $datadir/train_100k data/lang_gale_tdt \
                      $expdir/tri3b_ali_100k exp/tri4b
	utils/mkgraph.sh data/lang_gale_test $expdir/tri4b $expdir/tri4b/graph_gale_test || exit 1;
  steps/decode_fmllr.sh  --nj $decode_nj --cmd "$decode_cmd" \
  	$expdir/tri4b/graph_gale_test $datadir/eval $expdir/tri4b/decode_gale_eval &
fi

######################### Re-create lang directory######################
# We want to add pronunciation probabilities to lexicon, using the  previously trained model.
if [ $stage -le 9 ]; then
	steps/get_prons.sh --cmd "$train_cmd" \
                     data/train_100k data/lang_gale_tdt exp/tri4b
  utils/dict_dir_add_pronprobs.sh --max-normalize true \
                                  data/local/dict_gale_tdt \
                                  $expdir/tri4b/pron_counts_nowb.txt $expdir/tri4b/sil_counts_nowb.txt \
                                  $expdir/tri4b/pron_bigram_counts_nowb.txt data/local/dict_gale_tdt_reestimated

  utils/prepare_lang.sh data/local/dict_gale_tdt_reestimated \
                        "<UNK>" data/local/lang_gale_tdt_reestimated data/lang_gale_tdt_reestimated
	local/format_lms.sh --src-dir data/lang data/local/lm
	utils/build_const_arpa_lm.sh \
    data/local/lm/lm_fglarge.arpa.gz data/lang data/lang_test_fglarge
fi


echo "Reestimate pronunciations"
local/reestimation_lex.sh data/lang_gale_tdt_reest
echo "Pruning lexicon"
local/prune_lex.sh data/lang_gale_tdt_reest
# tri2a decoding
#utils/mkgraph.sh data/lang_gale_test $expdir/tri2a $expdir/tri2a/graph_gale_test || exit 1;
#steps/decode.sh --nj $decode_nj --cmd "$decode_cmd" \
#  $expdir/tri2a/graph_gale_test $datadir/eval $expdir/tri2a/decode_gale_eval &

steps/align_si.sh --nj $train_nj --cmd "$train_cmd" \
  $datadir/train_100k data/lang_gale_tdt_reest $expdir/tri2a exp/tri2a_ali_100k || exit 1;

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 4000 50000 \
  data/train data/lang exp/tri2a_ali exp/tri2b || exit 1;
utils/mkgraph.sh data/lang_test exp/tri2b exp/tri2b/graph || exit 1;
steps/decode.sh --nj $num_jobs_decode --cmd "$decode_cmd" exp/tri2b/graph data/dev exp/tri2b/decode &

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
  --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali  || exit 1;

if [ $stage -le 4 ]; then
  echo "Clean up TDT data"
  cp -r data/local/tdt_mandarin data/tdt/train
fi

if [ $stage -le 5 ]; then
  echo "Expand the lexicon with Gigaword"
  local/gigaword_prepare.sh $GIGA_TEXT $gigaData
  local/mandarin_prepare_dict.sh data/local/dict_giga_man_simp data/local/giga_man_simp
  local/mandarin_merge_dict.sh data/local/dict_gale_tdt data/local/dict_giga_man_simp data/local/dict_gale_tdt_giga
fi


if [ $stage -le 5 ]; then
  echo "Prepare LM with all data"
  # Train LM with gigaword
  local/mandarin_prepare_lm.sh --no-uttid "true" --ngram-order 4 --oov-sym "<UNK>" \
  data/local/dict_large GIGA/ data/local/giga_lm_4gram 



