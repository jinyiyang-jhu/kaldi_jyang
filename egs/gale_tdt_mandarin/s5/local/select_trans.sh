#!/bin/bash

stage=-1
srcdir=data/gale/eval
decodedir=

if [ $stage -le 0 ]; then
  for dset in tune eval; do
    datadir=data/gale_${dset}_mahsa_blank_ref
    for x in bc bn;do
      cp gale_${dset}_mahsa/$x/txt/allid.tmp $datadir/$x/allid.tmp
      info=$datadir/$x/allid.tmp
      for f in text segments; do
        awk 'NR==FNR{a[$3];next}$1 in a{print $0} ' $info $srcdir/$f > $datadir/$x/$f
      done
      awk '{print $2}' $info | uniq > $datadir/$x/wav.list
    done
  done
fi

