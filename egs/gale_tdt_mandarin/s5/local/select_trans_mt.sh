#!/bin/bash

stage=-1
srcdir=data/gale/eval
decodedir=

if [ $stage -le 0 ]; then
  for dset in tune eval; do
    datadir=gale_${dset}_mt
    for x in bc bn;do
      info=gale_${dset}_mt/$x/mt.clean.info.txt
      awk 'NR==FNR{
          st=sprintf("%d",$3*1000);et=sprintf("%d",$4*1000);
          uttid=$1"_"st"_"et;
          a[uttid];next
        }
        {
          st=sprintf("%d",$3*1000);et=sprintf("%d",$4*1000);
          uttid=$2"_"st"_"et;
          if (uttid in a){
            print $0;
          }
        }' $info $srcdir/segments > $datadir/$x/segments
      awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $datadir/$x/segments $srcdir/text > $datadir/$x/text
      awk '{print $1}' $info | uniq > $datadir/$x/wav.list
      awk 'NR==FNR{
          st=sprintf("%d",$3*1000);et=sprintf("%d",$4*1000);
          uttid=$2"_"st"_"et;
          a[uttid]=$1;next
        }
        {
          st=sprintf("%d",$3*1000);et=sprintf("%d",$4*1000);
          uttid=$1"_"st"_"et;
          if (uttid in a){
            print uttid" "a[uttid];
          }
          else{
            print uttid" empty";
          }
        }' $datadir/$x/segments $info > $datadir/$x/segments_mt_full
    done
  done
fi

