#!/usr/bin/perl -w

# This script generates time offset list files for each noise and
# SNR. These give the start time offsets into the noise file which are
# used when adding noise.  This script uses the create_list tool from
# the FaNT (Filtering and Noise-adding Tool) package in order to
# create these list files.

if (@ARGV != 0) { die "Read the comments at the top of $0 for information on how to use this.\n"; }

# Full list of the names of the noises.
@noiseNames= ("babble", "factory1", "volvo", "f16", "factory2", "buccaneer1", 
              "m109", "buccaneer2", "destroyerops", "leopard");

# The SNRs at which noise is added, along with 'clean' for no noise added.
@snrList = ("0", "5", "10", "15", "20", "clean");

$seed = 1000;

# For each noise and SNR (not including the "clean" SNR)
for ($noiseIndex = 0; $noiseIndex < @noiseNames; $noiseIndex++) {
    for ($snrIndex = 0; $snrIndex < @snrList-1; $snrIndex++) {

  	  $snr = $snrList[$snrIndex];
	
	  $noiseName = $noiseNames[$noiseIndex];
	  $noiseFile = "noises/postMIRS/" . $noiseName . ".raw";

	  $inList = "lists/in.$noiseName.snr$snr";
	  $offsetList = "lists/offsets.$noiseName.snr$snr";

  	  if (-f $offsetList) { unlink($offsetList) || die; } 

	  system("fant/create_list -i $inList -o $offsetList -n $noiseFile -r $seed") 
        && die "Error running create_list";

	  $seed = $seed + 1000;
    }
}


