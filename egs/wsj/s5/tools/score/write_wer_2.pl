#!/usr/bin/perl
use File::Basename;
my $name = basename($0);

$werfile = $ARGV[0];
$output = $ARGV[1];
$subname = "snr";

open(I,"<$werfile");
open(O,">$output");

while(<I>) {
	chomp;
	@array = split /\s+/,$_;
	~ m/$subname\_(.+)\/wer/;
	$snr = $1;
	$wer = $array[1];
	$hash{$snr} = $wer;
}
close I;

foreach $k (sort {$a<=>$b} keys(%hash)) {
	print O $k." ".$hash{$k}."\n";
}

close O;


