#!/usr/bin/perl -w

# This script creates the noisy Numbers corpus.
#
# It expects to find the input audio files under wavfiles/originals,
# and it will create the output audio files under wavfiles/noisy.
#
# This script uses file lists from the lists/ subdirectory together
# with the filter_add_noise tool in order to perform the noise-adding.
# For each noise and SNR, there is a list of input files (i.e.,
# originals before the noise adding) and a list of output files (i.e.,
# noise-added files).
#
# This script uses time offset files from the lists/ subdirectory
# for each noise and SNR. These give the start time offsets into the
# noise file which are used when adding noise.  These are provided in
# files, rather than having filter_add_noise calculate them on the
# fly, so that the noisy data will be created identically at different
# sites. They were created with the create_list tool from the FaNT
# package and the list-scripts/offsetlists.pl script.
#
# There is an SNR level of 'clean' for which no noise is added.
# This script simply copies over files at that SNR level without
# using using filter_add_noise.

##########################################################################

use strict;

# if (@ARGV != 0) { die "Read the comments at the top of $0 for information on how to use this.\n"; }

# Full list of the names of the noises.  
#my @noiseNames= ("babble", "factory1", "volvo", "f16", "factory2", "buccaneer1", 
#              "m109", "buccaneer2", "destroyerops", "leopard");

# my @noiseNames= ("babble", "benz" , "buccaneer1", "buccaneer2", "car", "destroyerops", "exhall", "f16", "factory1", "factory2", "leopard", "m109", "restuarant", "street", "subway", "volvo");
#my @noiseNames= ("restuarant","subway","destroyerops");
my @noiseNames= ("destroyerops");
# The SNRs at which noise is added, along with 'clean' for no noise added.
 my @snrList = ("-10","-9.5","-9","-8.5","-8","-7.5","-7","-6.5","-6","-5.5","-5","-4.5","-4","-3.5","-3","-2.5","-2","-1.5","-1","0","0.5","1","1.5","2","2.5","3","3.5","4","4.5","5","6","6.5","7","8","8.5","9","9.5","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30");

#my @snrList = ("6","6.5","7","8","8.5","9","9.5","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30");
#my @snrList = ("5.5");
#my @snrList = ("6","6.5","7","8","8.5","9","9.5","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30");
#my @snrList = ("5.5");

# Copy over the "clean" files which have no noise added.
#open(LIST, "lists/in.clean") || die "Cannot open lists/in.clean\n";
#while (my $inFile = <LIST>) {
#  chomp($inFile);

#  my $outFile = $inFile;
#  $outFile =~ s#wavfiles/originals/#wavfiles/noisy/#;
#  $outFile =~ s#\.raw#-clean.raw#;
#  makeDirForFile($outFile);
#  system("/bin/cp $inFile $outFile") && die "cp failed";
#}
#close(LIST);

# For each noise and SNR (not including the "clean" SNR)
for (my $noiseIndex = 0; $noiseIndex < @noiseNames; $noiseIndex++) {
  for (my $snrIndex = 0; $snrIndex < @snrList; $snrIndex++) {

    my $snr = $snrList[$snrIndex];

    my $noiseName = $noiseNames[$noiseIndex];
    my $noiseFile = "noises/preMIRS/" . $noiseName . ".raw";

    my $inList = "lists/in.new.$noiseName.snr$snr";
    my $outList = "lists/out.new.$noiseName.snr$snr";
    my $offsetList = "lists/offsets.new.$noiseName.snr$snr";
    
    # Make subdirectories for the output files.
    open(LIST, "$outList") || die "Cannot open $outList\n";
    while (my $outFile = <LIST>) {
      chomp($outFile);
      makeDirForFile($outFile);
    }
    close(LIST);

    # Log directory and log file.
    if (not(-d "log")) {
      system("/bin/mkdir -p log") && die "mkdir failed";
    }
    my $log = "log/fant.$noiseName.snr$snr.log";
    if (-f $log) { unlink($log) || die; }

    # Add the noise
    # system("/home/harish/timit_phoneme_recognition/FaNT/fant/filter_add_noise -d -m snr_4khz -i $inList -o $outList -n $noiseFile -s $snr -a $offsetList -e $log") && die "filter_add_noise failed";
    system("/home/harish/timit_phoneme_recognition/FaNT/fant/filter_add_noise -d -u -m snr_8khz -i $inList -o $outList -n $noiseFile -s $snr -a $offsetList -e $log") && die "filter_add_noise failed";
    # print "/home/harish/timit_phoneme_recognition/FaNT/fant/filter_add_noise -d -m snr_8khz -i $inList -o $outList -n $noiseFile -s $snr -a $offsetList -e $log\n";

  }
}

# Creates the directory containing the specified target file,
# if the directory doesn't already exist.
sub makeDirForFile {
  my $outFile = shift;
  
  # Extract directory part of output filename.
  $outFile =~ m#(.+)/[^/]+$#;
  my $directory = $1;

  if (not(-d $directory)) {
    system("/bin/mkdir -p $directory") && die "mkdir failed";
  }
}
