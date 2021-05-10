#!/usr/bin/env bash

# Copyright 2019 Johns Hopkins Univeersity (author: Jinyi Yang)
# Apache 2.0

if [ $# != 2 ]; then
  echo "$0 <gigaword-dir> <giga-lang-dir>"
  exit 0;
fi

giga_dir=$1
giga_lang_dir=$2

[ ! -d $giga_lang_dir ] && mkdir -p $giga_lang_dir;

find $giga_dir -name "*.gz" > $giga_lang_dir/giga_trans.flist || exit "Faile to find files"

if [ `wc -l $giga_lang_dir/giga_trans.flist | cut -d " " -f1` == 0 ]; then
  echo "Empty file list : $giga_lang_dir/giga_trans.flist"
  exit 1;
fi

for f in `cat $giga_lang_dir/giga_trans.flist`
do
  fname=$(basename "$f" ".gz")
  gunzip -c $f | \
    python3 local/gigaword_text_parse.py > $giga_lang_dir/$fname.tmp.txt
done

cat $giga_lang_dir/*.tmp.txt > $giga_lang_dir/raw.text
rm $giga_lang_dir/*.tmp.txt

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

cat $giga_lang_dir/raw.text |\
  perl local/mandarin_text_normalize.pl |\
  python2 local/mandarin_segment.py > $giga_lang_dir/filtered.text
cat $giga_lang_dir/filtered.text |\
  python2 local/mandarin_segment.py > $giga_lang_dir/segmented.text
mv $giga_lang_dir/segmented.text $giga_lang_dir/text
