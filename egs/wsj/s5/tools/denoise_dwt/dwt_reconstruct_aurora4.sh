#!/bin/bash

#if [ $# != 4 ];then
#    echo " Input: clean_dir noisy_audio_dir noisy_dir denoised_dir"
#    exit 1;
#fi

# cleandir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit/s5/data/test"
## noisy_audio_dir="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5/test_eval92_noise_${noisetype}_snr_${snr}"


#cleandir=$1 # Kaldi dir: with text, wav.scp ... etc
#noisy_audio_dir=$2 # with audio and wav.scp
#denoised_dir=$4 # Kaldi dir: with wav.scp, text ... etc
cmd=run.pl
noisetype=("street")
snr=("0")
nj=8
################## DWT parameters ##################
dwt_level=5
wav_name='db20'
ignore_level='[5]'
rec_with='d'
rec_level='d1234'
denoised_dir="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5/data/denoised_${wav_name}_L_${dwt_level}_${rec_with}_${rec_level}" 
####################################################

#denoised_audio_dir=`echo $noisy_audio_dir | sed "s@noisy@denoised_L_${dwt_level}_${rec_with}_${rec_level}@"` # with audio and wav.scp

for n in "${noisetype[@]}"
    do
    for s in "${snr[@]}"
        do
        echo "Processing for $n noise, $s dB ..."
        #suffix=denoised_${wname}_L_${dwt_level}_${rec_with}_${rec_level}/noise_${noise_type}_snr_${snr}
        ndir="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5/data_${noisetype}_noise/test_eval92_noise_${noisetype}_snr_${s}"
        dndir=$denoised_dir/noise_${n}_snr_${s}
        if [ ! -e $dndir ];then
            mkdir -p $dndir || exit "Unable to mkdir $dnir"
        fi
        sed "s@noise@denoised_${wav_name}_L_${dwt_level}_${rec_with}_${rec_level}@" $ndir/wav.scp > $dndir/wav.scp
        #cp $cleandir/{utt2spk,spk2utt,stm,glm,text} $dndir || exit "Unable to cp to $dndir"
        cp $ndir/{utt2spk,spk2utt,text} $dndir || exit "Unable to cp to $dndir"
        count=0
        total=`wc -l $ndir/wav.scp | cut -d " " -f1`
        while read line;
        do
            utt_id=`echo $line | cut -d " " -f1`
            echo "Denoising for utterance $utt_id ..."
            fname=`echo $line | cut -d " " -f2-`
            #clean_file=`grep -w $utt_id $cleandir/wav.scp | cut -d " " -f2`
            dn_file=`grep -w $utt_id $dndir/wav.scp | cut -d " " -f14`
            #dn_f=`grep -w $utt_id $dndir/wav.scp | cut -d " " -f14`
            ddir=`dirname $dn_file`
            #if [ -z $ddir ];then
            #    mkdir -p $ddir || exit "Fail to mkdir $ddir"
            #    echo "mkdir $ddir"
            #fi
            mkdir -p "${dn_file%/*}" || exit "mkdir failed: $dn_file"
            ./tools/denoise_dwt/dwt_reconstruct.py --nfile "$fname" \
            --dnfile $dn_file --level $dwt_level --wav_name $wav_name \
            --ign_level $ignore_level --c_or_d $rec_with \
            --uttid $utt_id || exit "Denoise failted at $utt_id"
          count=$((count+1))
          echo "$count/$total"
        done < $ndir/wav.scp
    done
done









