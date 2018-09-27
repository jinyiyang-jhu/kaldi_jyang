#!/bin/bash

seed=0

while read type; do
  while read snr; do
    echo ${type}_snr_${snr}
    rm -rf lists/offsets.new.${type}.snr${snr}
    for i in `seq 1 6300`; do
      number=`./getrand.o $seed`
      seed=$number
      echo $number >> ../lists/offsets.new.${type}.snr${snr}
    done 
  done < ../snr.list
done < ../noisetypes.list


