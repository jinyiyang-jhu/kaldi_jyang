#!/bin/bash

wav_dir="/export/b07/jyang/kaldi-update/kaldi/egs/aurora4_jinyi/s5/data_babble_noise/"
while read snr; do
	dir=$wav_dir/test_eval92_noise_street_snr_${snr}
	find $dir/ -name "*.wv1" > $dir/flist.txt
	perl local/flist2scp.pl $dir/flist.txt | sort > $dir/wav_tmp.scp
	awk '{printf("%s0 %s\n", $1, $2);}' $dir/wav_tmp.scp > $dir/wav_tmp2.scp
	awk '{printf("%s sox -L -r 16k -e signed -b 16 -c 1 -t raw %s -t wav - |\n", $1, $2);}'  $dir/wav_tmp.scp > $dir/wav.scp
	rm $dir/{wav_tmp*.scp,flist.txt}
done < tools/add_noise/addnoise/snr.list


