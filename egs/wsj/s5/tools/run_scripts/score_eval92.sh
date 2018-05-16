#!/bin/bash


lang_word=data/lang_unigram_flat
lang_phone=exp/tri2b_clean/phone_graph
decode_word=exp/nnet5c/decode_ugpr_5k_eval92
decode_phone=exp/nnet5c/decode_phone_graph_eval92


suffix=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d");


for s in "${suffix[@]}"
do
 (
 ./local/score.sh data/test_eval92_${s}/ $lang_word ${decode_word}_subset_${s}
  best_wer=`cat ${decode_word}_subset_${s}/wer_* | utils/best_wer.sh | cut -d " " -f 2`
  grep $best_wer ${decode_word}_subset_${s}/wer_* 
 # ./tools/dep_phone_tra_to_42_phonemes.pl data/test_eval92_0/text_phones data/test_eval92_0/text_indep.phones
#  paste -d " " <(cut -d " " -f1 data/test_eval92_${s}/utt2spk) <(cut -d " " -f 2- data/test_eval92_0/text_indep.phones) > data/test_eval92_${s}/text_phones_indep
#  ./local/score_per.sh data/test_eval92_${s}/ $lang_phone ${decode_phone}_subset_${s}
 #  cat ${decode_phone}_subset_${s}/wer_* | utils/best_wer.sh
  #best_per=`cat ${decode_phone}_subset_${s}/wer_* | utils/best_wer.sh | cut -d " " -f 2`
  #grep $best_per ${decode_phone}_subset_${s}/wer_* 

 ) &
 wait
done
