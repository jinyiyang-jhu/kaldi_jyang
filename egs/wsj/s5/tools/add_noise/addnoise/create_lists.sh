#!/bin/bash

while read n; do
  while read s; do
    c="noise_${n}_snr_${s}"
    echo $c
    cp ../original.raw.list lists/in.new.${n}.snr${s}
    sed "s@\/a07\/jyang\/experiments\/aurora4\/s5\/test_little_endian@\/b07\/jyang\/kaldi-update\/kaldi\/egs\/aurora4_jinyi\/s5\/data_${n}_noise\/test_eval92_${c}@g" ../original.raw.list > lists/out.new.${n}.snr${s}
    
    # while read d; do 
    #   mkdir -p $d
    #   sleep 0.01
    # done < temp.list
    # rm -f temp.list

  done < snr.list
done < noisetypes.list
