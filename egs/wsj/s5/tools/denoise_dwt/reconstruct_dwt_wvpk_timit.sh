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
noisetype=("white_700_900")
snr=("-5" "0" "5" "10")
nj=16
################## DWT parameters ##################
dwt_level=4
wav_name='db20'
ignores='[1,2]'
rec_with='cd'
ign_level='ign_12'
dwt_or_wvpk='wvpk'
suffix="denoised_${wav_name}_L_${dwt_level}_${dwt_or_wvpk}_${rec_with}_${ign_level}"
denoised_dir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit_dwt/s5/data/denoised_${wav_name}_L_${dwt_level}_${dwt_or_wvpk}_${rec_with}_${ign_level}"
####################################################


for n in "${noisetype[@]}"
    do
    for s in "${snr[@]}"
        do
        echo "Processing for $n noise, $s dB ..."
        ndir="/export/b07/jyang/kaldi-jyang/kaldi/egs/timit_dwt/s5/data/noisy/noise_${noisetype}_snr_${s}"
        dndir=$denoised_dir/noise_${n}_snr_${s}
        if [ ! -e $dndir ];then
            mkdir -p $dndir || exit "Unable to mkdir $dnir"
        fi
        #cp data/test/{glm,spk2utt,spk2gender,stm,text,utt2spk} $ndir
        #sed "s@noise@denoised_${wav_name}_L_${dwt_level}_${rec_with}_${rec_level}@" $ndir/wav.scp > $dndir/wav.scp
        cat $ndir/wav.scp | 
        sed "s@noisy@$suffix@"\
        > $dndir/wav.scp

        cp $ndir/{utt2spk,spk2utt,text,stm,glm} $dndir || exit "Unable to cp to $dndir"
        count=0
        total=`wc -l $ndir/wav.scp | cut -d " " -f1`
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
        done < $ndir/wav.scp
    done
done









