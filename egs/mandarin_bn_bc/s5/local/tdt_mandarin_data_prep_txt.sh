#!/usr/bin/env bash

# Copyright 2019 Johns Hopkins University (author: Jinyi Yang)
# Apache 2.0

. ./path.sh || exit 1;

echo $0 "$@"
export LC_ALL=C

tdtData=$(utils/make_absolute.sh "${@: -1}" );

length=$(($#-1))
args=${@:1:$length}

top_pwd=`pwd`
txtdir=$tdtData/txt
sph_scp=$tdtData/wav.scp
mkdir -p $txtdir

cd $txtdir

for cdx in ${args[@]}; do
  echo "Preparing $cdx"
  if [[ $cdx  == *.tgz ]] ; then
     tar -zxf $cdx
  elif [  -d "$cdx" ]; then
    tgt=$(basename $cdx)
    zfile=`find $cdx -type f -name *.tgz`
    if [ ! -z $zfile ]; then
      test -x $tgt || mkdir $tgt
      cd $tgt
      tar -zxf $zfile
      cd $txtdir
    else
      test -x $tgt || ln -s $cdx `basename $tgt`
    fi
  else
    echo "I don't really know what I shall do with $cdx " >&2
  fi
done

# There are more transcriptions that audio files. We only use that
# transcriptions which have corresponding audio files.
find -L $txtdir -type f -name *.src_sgm | grep "MAN" | \
  awk 'NR==FNR {a[$1];next}; {name=$0;gsub(".src_sgm$", "", name); gsub(".*/", "", name); \
    if (name in a) print $0}' $sph_scp - | sort > $txtdir/trans.flist  || exit 1;

perl $top_pwd/local/tdt_mandarin_parse_sgm.pl $txtdir/trans.flist > $txtdir/text.tmp || exit 1;
cd $top_pwd

cut -d " " -f1 $txtdir/text.tmp > $txtdir/uttid
cut -d " " -f2- $txtdir/text.tmp > $txtdir/trans

pyver="2.7"
export PYTHONPATH=$PYTHONPATH:`pwd`/tools/mmseg-1.3.0/lib/python${pyver}/site-packages
if [ ! -d $KALDI_ROOT/tools/mmseg-1.3.0/lib/python${pyver}/site-packages ]; then
  echo "--- Installing mmseg 1.3 ..."
  echo "NOTE: it assumes that you have Python2 environment, Setuptools installed on your system!"
  cd $KALDI_ROOT/tools/extras
  bash install_mmseg.sh
  if [ ! -d $KALDI_ROOT/tools/mmseg-1.3.0/lib/python${pyver}/site-packages ]; then
    echo "mmseg is not found - installation failed?"
    exit 1
  fi
  cd $top_pwd
fi

# Create text, use mmseg for splitting Mandarin characters into words.
cat $txtdir/trans |\
   sed -e 's/,//g' | \
   sed -e 's/((\([^)]\{0,\}\)))/\1/g' |\
   perl local/mandarin_text_normalize.pl |\
   python local/mandarin_segment.py |\
   sed -e 's/THISISSPKTURN/<TURN>/g' |\
   paste $txtdir/uttid - |\
   awk '{if (NF>2 || (NF==2 && $2 != "<TURN>")) print $0}' > $txtdir/text_with_spk_turn

# The text_with_spk_turn file contains label "<TURN>" to indicate speaker
# switching, in case the speaker diarization process is required. We do not use
# speaker diarization at this moment, so the spk id will be the segment
# (utterance)

cat $txtdir/text_with_spk_turn | sed 's/<TURN>//g' > $txtdir/text
awk '{print $1" "$1}' $txtdir/text_with_spk_turn > $txtdir/utt2spk
cp $txtdir/utt2spk $txtdir/spk2utt

awk '{segments=$1; split(segments, S, "_"); uttid=S[1];for (i=2;i<=5;++i) uttid=uttid"_"S[i]; print segments " " uttid " " S[7]/100 " " S[8]/100}' < $txtdir/text > $txtdir/segments

awk '{print $1}' $txtdir/text > $txtdir/uttid

echo "TDT Mandarin text preparation succeed !"
