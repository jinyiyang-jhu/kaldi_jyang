#!/usr/bin/perl
#
#
#
#This script compute kv-avrg per spk is not accurate. It sums up all kl-avrg by utts and divided by number of spks.
#

$in = $ARGV[0]; # wer_vs_kl.txt file
$out = $ARGV[1];

open (IN,"<$in");
open (OUT,">$out");

%hash_wer = ();
%hash_kl = ();
$count = 0;
while (<IN>)
{
	chomp;
	my @array = split/\s+/,$_;
	$utt = shift @array;
	$wer = shift @array;
	$kl = shift @array;
	$spk = substr $utt, 0, 3;
	if ( exists $hash_wer{$spk} )
	{
		$hash_wer{$spk} += $wer;
	       	$hash_kl{$spk} += $kl;
	}
	else
	{
		
		$hash_wer{$spk} = $wer;
		$hash_kl{$spk} = $kl;
		$count ++;
	}
}
close IN;

foreach my $key (sort keys %hash_wer)
{
	my $wer = $hash_wer{$key}/$count;
	my $kl = $hash_kl{$key}/$count;
	print OUT $key." ".$wer." ".$kl."\n";
	print "spk is is $key\n";
}
close OUT;


