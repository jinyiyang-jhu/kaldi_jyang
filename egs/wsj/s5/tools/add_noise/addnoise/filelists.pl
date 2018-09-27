#!/usr/bin/perl -w

# For each noise and SNR, this script creates an input list file in
# the lists/ subdirectory listing the audio files which that noise is
# to be added to at that SNR, and an output list file in the lists/
# subdirectory listing the resulting output audio files.  For the
# audio files for which no noise is added, only an input list file
# lists/in.clean is created, since an output list file is only needed
# when the FaNT filter_add_noise tool is used.  This tool also creates
# lists/train.list.noisy.rand, lists/val.list.noisy.rand,
# lists/test.list.noisy.rand.  These are lists of the training set,
# validation set and test set files for the noisy Numbers corpus.

use strict;

if (@ARGV != 0) { die "Read the comments at the top of $0 for information on how to use this\
.\n"; }

# Full list of the names of the noises.
my @noiseNames= ("babble", "factory1", "volvo", "f16", "factory2", "buccaneer1", 
              "m109", "buccaneer2", "destroyerops", "leopard");

# The SNRs at which noise is added, along with 'clean' for no noise added.
my @snrList = ("0", "5", "10", "15", "20", "clean");

# For each noise and SNR (not including the "clean" SNR), remove the
# corresponding input and output list file if there is a copy lying
# around, so it can be created from scratch.
my $list = "lists/in.clean";
if (-f $list) { unlink($list) || die; }
for (my $noiseIndex = 0; $noiseIndex < @noiseNames; $noiseIndex++) {
    for (my $snrIndex = 0; $snrIndex < @snrList-1; $snrIndex++) {
	$list = "lists/in.$noiseNames[$noiseIndex].snr$snrList[$snrIndex]";
	if (-f $list) { unlink($list) || die; }
	$list = "lists/out.$noiseNames[$noiseIndex].snr$snrList[$snrIndex]";
	if (-f $list) { unlink($list) || die; }
    }
}

makeLists("lists/train.list.rand", "lists/train.list.noisy.rand", ["babble", "factory1", "volvo", "f16", "factory2", "buccaneer1"]);
makeLists("lists/val.list.rand", "lists/val.list.noisy.rand", ["babble", "factory1", "volvo", "f16", "m109", "buccaneer2"]);
makeLists("lists/test.list.rand", "lists/test.list.noisy.rand", ["babble", "factory1", "volvo", "f16", "destroyerops", "leopard"]);

sub makeLists {

  my $randList = shift;  
  my $outputRandList = shift;
  my $noiseListRef = shift; 
  my @noiseList = @$noiseListRef;

  # Open list of files for this part in random order.
  open(LIST, $randList) || die "Cannot open $randList";
  open(OUTPUTLIST, ">$outputRandList") || die "Cannot open $outputRandList";
    
  my $snrIndex = 0;
  my $noiseIndex = 0;

  my $file;
  while ($file = <LIST>) {
    chomp($file);

    my $inFile = "wavfiles/originals/" . $file . ".raw";
    my $outFile = "";
    
    my $snr = $snrList[$snrIndex];
    $snrIndex = ($snrIndex + 1 ) % @snrList;

    if ($snr eq "clean") {
      my $list = "lists/in.clean";
      open(IN, ">>$list") || die;
      print IN "$inFile\n";
      close(IN);

      $outFile = "wavfiles/noisy/" . $file . "-clean.raw";
    } else {
      my $noiseFile = $noiseList[$noiseIndex];
      $noiseIndex = ($noiseIndex + 1 ) % @noiseList;

      $outFile = "wavfiles/noisy/" . $file . "-snr${snr}-${noiseFile}.raw";

      my $list = "lists/in.$noiseFile.snr$snr";
      open(IN, ">>$list") || die;
      print IN "$inFile\n";
      close(IN);
	    
      $list = "lists/out.$noiseFile.snr$snr";
      open(OUT, ">>$list") || die;
      print OUT "$outFile\n";
      close(OUT);
    }
    
    print OUTPUTLIST $outFile . "\n";
  }
  
  close(LIST) || die;
  close(OUTPUTLIST) || die;
}
