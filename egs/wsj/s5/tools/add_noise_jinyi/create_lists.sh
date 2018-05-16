#!/bin/bash

if [ $# != 3 ];then
    echo "Usage: input1:wavlist, input2:snrlist, input3:noisetype.list"
    exit 1;
fi

## Check Line 25 for updating new data directory

lists=$(dirname $0)/lists

if [ -e $lists ];then
    rm -r $lists
fi
    mkdir $lists

while read n; do
  while read s; do
    c="noise_${n}_snr_${s}"
    cp $1 $lists/in.new.${n}.snr${s}
    #paste -d " " <(cut -d " " -f1 $1) \
    #<(cut -d " " -f5 $1 | \
    #sed "s@corpora5\/LDC\/LDC93S1@b07\/jyang\/kaldi-jyang\/kaldi\/egs@" |\
    #sed "s@timit@timit_dwt\/s5\/data\/noisy\/${c}@") > $lists/out.new.$n.snr${s}
    paste -d " " <(cut -d " " -f1 $1) \
    <(cut -d " " -f5 $1 | \
    sed "s@corpora5\(.*\)LDC\/@b07\/jyang\/kaldi-jyang\/kaldi\/egs\/wsj\/s5\/data_noisy\/@") |\
    sed "s@wv1@wav@" > $lists/out.new.$n.snr${s}

    # while read d; do
    #   mkdir -p $d
    #   sleep 0.01
    # done < temp.list
    # rm -f temp.list

  done < $2
done < $3
