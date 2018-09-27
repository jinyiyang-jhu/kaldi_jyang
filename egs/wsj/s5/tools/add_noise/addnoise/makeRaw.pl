#!/usr/bin/perl -w

# This takes the MSWAVE format audio files provided on the
# Numbers corpus CD and creates headerless versions for use
# with the filter_add_noise tool.  The headerless versions
# have the filename suffix .raw.  You must have the sox
# audio file tool in your path. The output files will be
# placed under a directory named originals.

if (@ARGV != 2) {
  die "Usage: $0 <prefix> <listfile>\n";
}

$prefix = $ARGV[0];
$list = $ARGV[1];

open(LIST, $list) || die "Cannot open list $list";

while ($file = <LIST>) {
  chomp($file);

  $inFile = $prefix . $file . '.wav';

  $outFile = "originals/" . $file . '.raw';

  # Find the directory part of the output filename.
  $outDir = $outFile;
  $outDir =~ s#/[A-Za-z0-9\.\-]*$##;

  if (not(-d $outDir)) {
    system("mkdir -p $outDir") && die "mkdir failed";
  }

  # Sox knows what formats are involved based on the
  # .wav and .raw suffixes.
  system("sox $inFile $outFile") && warn "sox failed\n"; 
}

