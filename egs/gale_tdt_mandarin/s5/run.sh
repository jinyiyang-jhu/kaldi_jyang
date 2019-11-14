#!/bin/bash


. path.sh
. cmd.sh

num_jobs=64
num_decode_jobs=40


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

galeData=GALE/
tdtData=TDT/

set -e -o pipefail
set -x

#local/gale_data_prep_audio.sh "${GALE_AUDIO[@]}" $galeData
#local/gale_data_prep_txt.sh  "${GALE_TEXT[@]}" $galeData

#local/tdt_mandarin_data_prep_audio.sh "${TDT_AUDIO[@]}" $tdtData
local/tdt_mandarin_data_prep_txt.sh  "${TDT_TEXT[@]}" $tdtData
