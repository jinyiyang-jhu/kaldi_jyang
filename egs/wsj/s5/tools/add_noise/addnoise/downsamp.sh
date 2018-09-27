while read noise
do
	echo $noise
	sndrfmt -S MSWAVE -T PCM/R16000 -V noises/preMIRS/$noise.wav  noises/preMIRS/$noise.raw
done < noisetypes.list

