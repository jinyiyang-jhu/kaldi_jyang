inpdir="../dev10h.pem_raw"
oupdir="../dev10h.pem_noisy"

while read type
do
	while read snr
	do
		echo ${type}_snr_${snr}
		rm -rf lists/in.new.${type}.snr${snr}
		rm -rf lists/out.new.${type}.snr${snr}
		outdir=${oupdir}_${type}_snr_${snr}
		mkdir -p $outdir
		while read line
		do
			
			ipfile=${inpdir}/${line}.raw
                        outdir=${oupdir}_${type}_snr_${snr}
#			mkdir -p ${outdir}
			opfile=$outdir/${line}.raw
			echo $ipfile >> lists/in.new.${type}.snr${snr}
        		echo $opfile >> lists/out.new.${type}.snr${snr}
	        done < ../dev10h.pem.list
	done < snr.list
done < noisetypes.list
