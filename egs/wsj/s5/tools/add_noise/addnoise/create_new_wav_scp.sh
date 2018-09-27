#!/bin/bash

if [ $# != 2 ];then
    echo "input is snr.list noisetype.list"
    exit 1;
fi

creat="yes"
convert="yes"
basedir=/export/b07/jyang/kaldi-jyang/kaldi/egs/timit/s5
name=("TRAIN" "TEST")
snrlist=$1
noiselist=$2

while read n; do
    echo "Noise type is $n"
    while read snr;do
        echo "SNR is $snr"
        dir=$basedir/data_noisy_mine/noise_${n}_snr_${snr}
        if [ $creat == "yes" ];then
            for s in "${name[@]}"
            do
                find $dir/$s/*/*/*.WAV > $dir/${s}.list || exit 1;
                awk -F "/" '{sting=gsub(".WAV","",$NF); print $(NF-1)"_"$NF}' $dir/${s}.list \
                > $dir/$s.uttid 
                paste -d " " <(cat $dir/$s.uttid) \
                <(awk '{print "sox -b 16 -e signed-integer -c 1 -r 16k -t raw "$0" -t wav - |"}' $dir/$s.list)\
                > $dir/$s.scp
            done
        fi
        if [ $convert == "yes" ];then
            newdir=$(echo $dir | sed "s/data_noisy/data_noisy_wav/")
            echo "Converting raw to wav..."
            echo "New dir is in $newdir"
            if [ ! -d $newdir ]; then
                mkdir $newdir
            fi
            for s in "${name[@]}"
            do
                awk '{gsub("data_noisy", "data_noisy_wav",$0); print $0}' $dir/$s.list \
            > $dir/${s}_wav.list
            paste <(awk '{print "sox -b 16 -e signed-integer -c 1 -r 16k -t raw "$0" -t wav "}' $dir/$s.list) \
             <(cat $dir/${s}_wav.list) > $dir/${s}_wav.sh || exit 1;
            chmod 755 $dir/${s}_wav.sh
           while read line; do
                 mkdir -p "${line%/*}";
            done < $dir/${s}_wav.list
            $dir/${s}_wav.sh || exit "Converting failed..."
            paste -d " " $dir/$s.uttid $dir/${s}_wav.list > $newdir/${s}_wav.scp
            done
        fi
    done < $snrlist
done < $noiselist

