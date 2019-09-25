#!/bin/bash

# VAST data will be used only as eval set

corpus_dir=/export/corpora/LDC/LDC2019S05/vast_cmn_transcription/data
VAST_data=VAST/

. path.sh

local/vast_data_prep_audio.sh $corpus_dir/audio $VAST_data
local/vast_data_prep_txt.sh  $corpus_dir/transcript $VAST_data
local/vast_data_prep_format.sh VAST/ $eval_name
cp -prT data/local/vast_eval data/$eval_name


echo "VAST data preparation succeeded !"











