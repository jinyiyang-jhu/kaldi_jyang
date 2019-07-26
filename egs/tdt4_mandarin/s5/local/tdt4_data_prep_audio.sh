#!/bin/bash

. ./path.sh || exit 1;

if [ $# != 1 ]; then
    echo "Usage: $0 <audio-path>"
    echo "$0 /export/corpora/LDC/LDC2005S11/"
    echo 1;
fi

tdt4_audio_dir=$1
tmpdir=data/local

# Check data directory
if [ ! -d $tdt4_audio_dir ]; then
    echo "Error: $0 requires $tdt4_audio_dir !"
    exit 1;
fi
# Check if sph2pipe is installed
sph2pipe=`which sph2pipe` || sph2pipe=$KALDI_ROOT/tools/sph2pipe_v2.5/sph2pipe
[ ! -x $sph2pipe ] && echo "Could not find the sph2pipe program at $sph2pipe" && exit 1;

mkdir -p $tmpdir

# Find all TDT4 Mandarin audios
find /export/corpora/LDC/LDC2005S11/TDT4_MAN_*/sph/* -iname "*.sph" > $tmpdir/all_sph.flist || exit 1;

nfiles=`cat $tmpdir/all_sph.flist | wc -l`
[ $nfiles -ne 424 ] && echo "Warning: expected 424 sph files, found $nfiles"

awk '{name = $0; gsub(".sph$","",name); gsub(".*/","",name); print(name " " $0)}' $tmpdir/all_sph.flist > $tmpdir/all_sph.scp

# There are two channels in each audio containing same content, so we only keep the first channel audio
cat data/local/all_sph.scp | awk -v sph2pipe=$sph2pipe '{printf("%s %s -f wav -p -c 1 %s |\n", $1, sph2pipe, $2);}' | sort > $tmpdir/all_wav.scp


