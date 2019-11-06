#!/bin/bash

lex=data/local/dict/lexicon.txt
fname=$1

cat $fname | awk '{for(n=2;n<=NF;n++) { print $n; }}' | \
 perl -e '$lex = shift @ARGV; open(L, "<$lex")||die; while(<L>){ @A=split; $seen{$A[0]}=1;}
   while(<STDIN>) { @A=split; $word=$A[0]; $tot++; if(defined $seen{$word}) {$invoc++; } else {print "OOV word $word\n";}}
   $oov_rate = 100.0 * (1.0 - ($invoc / $tot)); printf("Seen $invoc out of $tot tokens; OOV rate is %.2f\n", $oov_rate);  ' $lex
