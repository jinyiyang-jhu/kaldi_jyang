#!/bin/bash

. ./path.sh || exit 1;

if [ $# != 1 ]; then
    echo "Usage: $0 <transcription-path>"
    echo "$0 /export/corpora/LDC/LDC2005T16/"
    exit 1;
fi

tdt4_text_dir=$1/data/src_sgm # Here we use original source text data in SGML format.
tmpdir=data/local


if [ ! -d $tdt4_text_dir ]; then
    echo "Error: $0 requires $tdt4_text_dir !"
    exit 1;
fi

set -e -o pipefail
set -x

sph_scp=$tmpdir/all.wav.scp

# Find transcriptions for Mandarin audio data. There are more text than audios,
# so we only choose the transcriptions with corresponding audio data.
#find $tdt4_text_dir -name "*MAN.src_sgm" | awk 'NR==FNR {a[$1];next}; {name=$0;gsub(".src_sgm$", "", name); gsub(".*/", "", name); if (name in a) print $0}'  $sph_scp - | sort > $tmpdir/all_trans.flist  || exit 1;
find $tdt4_text_dir -name "*MAN.src_sgm" | \
  awk 'NR==FNR {a[$1];next}; {name=$0;gsub(".src_sgm$", "", name); gsub(".*/", "", name); \
    if (name in a) print $0}' $sph_scp - | sort > $tmpdir/all_trans.flist  || exit 1;
perl local/tdt4_mandarin_parse_sgm.pl $tmpdir/all_trans.flist > $tmpdir/alltext.tmp || exit 1;
cut -d " " -f1 $tmpdir/alltext.tmp > $tmpdir/all.uttid
#cut -d " " -f2- $tmpdir/alltext.tmp | sed 's/\s\+//g' > $tmpdir/all.trans
cut -d " " -f2- $tmpdir/alltext.tmp > $tmpdir/all.trans

# Create text, use mmseg for splitting Mandarin characters into words.
cat $tmpdir/all.trans |\
   sed -e 's/,//g' | \
   sed -e 's/((\([^)]\{0,\}\)))/\1/g' |\
   local/tdt4_mandarin_normalize.pl |\
   python local/tdt4_mandarin_segment.py |\
   sed -e 's/THISISSPKTURN/<TURN>/g' |\
   paste $tmpdir/all.uttid - |\
   awk '{if (NF>2 || (NF==2 && $2 != "<TURN>")) print $0}' > $tmpdir/all.text

awk '{spk=substr($1,1,26);print $1" "spk}' $tmpdir/all.text > $tmpdir/all.utt2spk || exit 1;
cat $tmpdir/all.utt2spk | sort -k 2 | utils/utt2spk_to_spk2utt.pl > $tmpdir/all.spk2utt || exit 1;

awk '{segments=$1; split(segments, S, "_"); uttid=S[1];for (i=2;i<=5;++i) uttid=uttid"_"S[i];
  print segments " " uttid " " S[7]/100 " " S[8]/100}' < $tmpdir/all.text > $tmpdir/all.segments

awk '{print $1}' $tmpdir/all.text > $tmpdir/all.uttid
echo "TDT4 Mandarin text preparation succeed !"
