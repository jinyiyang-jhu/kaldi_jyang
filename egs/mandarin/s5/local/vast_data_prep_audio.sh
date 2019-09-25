#!/bin/bash

# Copyright 2014 QCRI (author: Ahmed Ali)
# Copyright 2016 Johns Hopkins Univeersity (author: Jan "Yenda" Trmal)
# Apache 2.0


vast_audio=$1
vastData=$(utils/make_absolute.sh "${@: -1}" );


wavedir=$vastData/audio
mkdir -p $wavedir

# check that sox is installed
which sox  &>/dev/null
if [[ $? != 0 ]]; then
 echo "$0: sox is not installed"
 exit 1
fi

set -e -o pipefail
find $vast_audio -type f -name *.flac  | while read file; do
    f=$(basename $file)

    if [[ ! -L "$wavedir/$f" ]]; then
      ln -sf $file $wavedir/$f
    fi
done

#figure out the proper sox command line
#the flac will be converted on the fly

(for w in `find $wavedir -name *.flac` ; do
    base=`basename $w .flac`
    fullpath=`utils/make_absolute.sh $w`
    echo "$base sox $fullpath -r 16000 -t wav - |"
done
) | sort -u > $vastData/wav.scp

#clean
rm -fr $vastData/id$$ $vastData/wav$$
echo "$0: data prep audio succeded"

exit 0

