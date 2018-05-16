#!/bin/bash

if [ $# != 4 ];then
    echo "$0 input_wav.scp output_dir snr_list noisetype_list"
    exit 1
fi

iwvlist=$1
owvdir=$2
snrlist=$3
noiselist=$4
ipipe="True"


if [ ! -f $owvdir/add_noise.py ];then
    cmdfile="/export/b07/jyang/kaldi-jyang/kaldi/egs/wsj/s5/tools/add_noise_jinyi/add_noise.py"
    echo "Copy $cmdfile to your directory and chmod"
    exit 1
fi

noisedir='/home/jyang/timit_phoneme_recognition/fant/noises/preMIRS'
while read n; do
    echo "Noise type is $n"
    noisefile=$noisedir/$n.wav
    while read s; do
        echo "SNR is $s"
        olist=$owvdir/wav_noise_${n}_snr_${s}.scp
        noisefile=$noisedir/$n.wav
        awk '{print $0" python3 add_noise.py - --n '$noisefile' --ipipe '$ipipe' --snr '$s' |"}' $iwvlist > $olist
    done < $snrlist
done < $noiselist

