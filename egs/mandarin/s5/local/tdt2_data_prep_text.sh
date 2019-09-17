#!/bin/bash

. ./path.sh || exit 1;

if [ $# != 2 ]; then
    echo "Usage: $0 <transcription-path> <tgtdir>"
    echo "$0 tdt2_em/src_sgm data/local/tdt2"
    exit 1;
fi

tdt4_text_dir=$1  # Here we use original source text data in SGML format.
tmpdir=$2


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

pyver=`python --version 2>&1 | sed -e 's:.*\([2-3]\.[0-9]\+\).*:\1:g'`
export PYTHONPATH=$PYTHONPATH:`pwd`/tools/mmseg-1.3.0/lib/python${pyver}/site-packages
if [ ! -d tools/mmseg-1.3.0/lib/python${pyver}/site-packages ]; then
  echo "--- Downloading mmseg-1.3.0 ..."
  echo "NOTE: it assumes that you have Python, Setuptools installed on your system!"
  wget -P tools http://pypi.python.org/packages/source/m/mmseg/mmseg-1.3.0.tar.gz
  tar xf tools/mmseg-1.3.0.tar.gz -C tools
  cd tools/mmseg-1.3.0
  mkdir -p lib/python${pyver}/site-packages
  CC=gcc CXX=g++ python setup.py build
  python setup.py install --prefix=.
  cd ../..
  if [ ! -d tools/mmseg-1.3.0/lib/python${pyver}/site-packages ]; then
    echo "mmseg is not found - installation failed?"
    exit 1
  fi
fi
# Create text, use mmseg for splitting Mandarin characters into words.
cat $tmpdir/all.trans |\
   sed -e 's/,//g' | \
   sed -e 's/((\([^)]\{0,\}\)))/\1/g' |\
   local/text_normalize.pl |\
   python local/segment.py |\
   sed -e 's/THISISSPKTURN/<TURN>/g' |\
   paste $tmpdir/all.uttid - |\
   awk '{if (NF>2 || (NF==2 && $2 != "<TURN>")) print $0}' > $tmpdir/all.text

#awk '{spk=substr($1,1,26);print $1" "spk}' $tmpdir/all.text > $tmpdir/all.utt2spk || exit 1;
#cat $tmpdir/all.utt2spk | sort -k 2 | utils/utt2spk_to_spk2utt.pl > $tmpdir/all.spk2utt || exit 1;
awk '{print $1" "$1}' $tmpdir/all.text > $tmpdir/all.utt2spk
cp $tmpdir/all.utt2spk  $tmpdir/all.spk2utt

awk '{segments=$1; split(segments, S, "_"); uttid=S[1];for (i=2;i<=5;++i) uttid=uttid"_"S[i];
  print segments " " uttid " " S[7]/100 " " S[8]/100}' < $tmpdir/all.text > $tmpdir/all.segments

awk '{print $1}' $tmpdir/all.text > $tmpdir/all.uttid
echo "TDT Mandarin text preparation succeed !"
