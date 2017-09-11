#!/bin/bash

noise=street
snr=30
wer_dir="exp/nnet5c/decode_tgpr_5k_eval92_noise_${noise}_snr_${snr}/wer_per_utt"
result_dir="eval92_noise_${noise}_results/snr_${snr}_wer_lmwt_10_utt"
kl="KL_div/eval92_word_tgpr_5k_vs_phone_3gram_skip_frame_th_2.0_noise_${noise}/snr_${snr}/KL_sys_medfilt_11_phone_window_0.txt"
stage=-1



if [ $stage -le 0 ];then
	 ./local/score_wer_per_sen.sh data_${noise}_noise/test_eval92_noise_${noise}_snr_${snr} data/lang_test_tgpr_5k/ exp/nnet5c/decode_tgpr_5k_eval92_noise_${noise}_snr_${snr}
 fi

if [ $stage -le 1 ];then
	awk '{sum=0;for(i=2;i<=NF;i++) sum+=$i} {print $1" "sum/(NF-1)}' $kl > eval92_noise_${noise}_results/kl_avrg_utt_snr_${snr}.txt
fi
cp -r $wer_dir $result_dir 

grep WER $result_dir/lmwt_10/* | cut -d "/" -f4 | sed 's@wer_@@g' | sed 's@:%WER@@g' | cut -d "[" -f1 \
	> eval92_noise_${noise}_results/wer_utt_snr_${snr}_lmwt_10.txt

paste -d " " <(cat eval92_noise_${noise}_results/kl_avrg_utt_snr_${snr}.txt) <( cut -d " " -f2 eval92_noise_${noise}_results/wer_utt_snr_${snr}_lmwt_10.txt) | sort -k3 -n > eval92_noise_${noise}_results/kl-avrg_vs_wer_utt_snr_${snr}.txt
