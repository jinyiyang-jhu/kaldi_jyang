#!/bin/bash

D="/export/harish2/TIMIT_noisy/LDC/LDC93S1/timit/TIMIT"

while read n; do
while read s; do
c="noisy_${n}_snr_${s}"
echo $c    
for h in `cat original.list`; do
  echo $h
  f1=`dirname $h`"/"`basename $h .WAV`".RAW"
  f=`echo $f1 | sed "s@timit/TIMIT@timit/TIMIT_${c}@g"` 
  x=`dirname $f`"/"`basename $f .RAW`".WAV"
  echo $f
  echo $x

  # sph2pipe -f raw $x > $f
  sph2pipe -h $h -f sph $f > $x
  # mv temp.WAV $x

done
done < addnoise/snr.list
done < addnoise/noisetypes.list

