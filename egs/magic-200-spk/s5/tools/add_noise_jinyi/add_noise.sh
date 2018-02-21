#!/bin/bash

if [ $# != 3 ];then
    echo "input: wav.scp/wav.list"
    echo "snrlist"
    echo " noisetype.list"
    exit 1
fi

iwvlist=$1
snrlist=$2
noiselist=$3
basedir=`dirname $0`
$basedir/create_lists.sh $iwvlist $snrlist $noiselist

noisedir=$basedir/noises
while read n; do
    echo "Noise type is $n"
    noisefile=$noisedir/$n.wav
    while read s; do
        echo "SNR is $s"
        ilist=$basedir/lists/in.new.$n.snr${s}
        olist=$basedir/lists/out.new.$n.snr${s}
        $basedir/add_noise.py --i $ilist --o $olist --n $noisefile --snr $s
    done < $snrlist
done < $noiselist

