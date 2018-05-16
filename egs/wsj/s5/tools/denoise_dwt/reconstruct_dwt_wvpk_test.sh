#!/bin/bash

#if [ $# != 4 ];then
#    echo " Input: clean_dir noisy_audio_dir noisy_dir denoised_dir"
#    exit 1;
#fi

# cleandir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit/s5/data/test"
## noisy_audio_dir="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5/test_eval92_noise_${noisetype}_snr_${snr}"


cmd=run.pl
bands=("remove_700_1300")
#snr=("-5" "0" "5" "10")
################## DWT parameters ##################
dwt_level=4
wav_name='db20'
ignores='[1,2]'
rec_with='cd'
ign_level='ign_12'
dwt_or_wvpk='wvpk'
suffix="${wav_name}_L_${dwt_level}_${dwt_or_wvpk}_${rec_with}_${ign_level}"
subbands_dir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit_dwt/s5/data/test_subbands"
test_dir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit_dwt/s5/data/test"
####################################################


for n in "${bands[@]}"
    do
        echo "Processing for $n noise, $s dB ..."
        dndir=$subbands_dir/subbands_${n}/$suffix
        if [ ! -e $dndir ];then
            mkdir -p $dndir || exit "Unable to mkdir $dnir"
        fi
        cut -d "/" -f1,21- $test_dir/wav.scp |\
        awk '{print $1" "dndir$2}' dndir=$dndir > $dndir/wav.scp
        if [ ! -s $dndir/wav.scp ];then
            echo "$dndir/wav.scp empty"
            exit 1
        fi
        cp $test_dir/{utt2spk,spk2utt,text,stm,glm} $dndir || exit "Unable to cp to $dndir"
        count=0
        total=`wc -l $test_dir/wav.scp | cut -d " " -f1`
        while read line;
        do
            utt_id=`echo $line | cut -d " " -f1`
            echo "Denoising for utterance $utt_id ..."
            fname=`echo $line | cut -d " " -f2-`
            dn_file=`grep -w $utt_id $dndir/wav.scp | cut -d " " -f2-`
            ddir=`dirname $dn_file`
            mkdir -p "${dn_file%/*}" || exit "mkdir failed: $dn_file"
            ./tools/denoise_dwt/reconstruct_dwt_wvpk.py --nfile "$fname" \
            --dnfile $dn_file --level $dwt_level --wav_name $wav_name \
            --dwt_or_wvpk $dwt_or_wvpk \
            --ign $ignores --c_or_d $rec_with \
            --uttid $utt_id || exit "Denoise failted at $utt_id"
          count=$((count+1))
          echo "$count/$total"
        done < $test_dir/wav.scp
done









