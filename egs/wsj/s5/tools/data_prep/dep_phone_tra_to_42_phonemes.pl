#!/usr/bin/perl
#
#
$in=$ARGV[0];
$out=$ARGV[1];
$map="./phone_mappings/map_root_sys-vs-dep_phone_sys.map";

open(IN,"<$in");
open(OUT,">$out");
open(MAP,"<$map");


while (<MAP>) {
	chomp;
	my @a = split /\s+/,$_;
	my $root = shift @a;
	foreach my $k (@a) {
		$hash{$k} = $root;
		#	print $root."\n";
	}
}
close MAP;

while(<IN>) {
	chomp;
	my @b = split /\s+/,$_;
	$utt = shift @b;
	print OUT $utt." ";
	foreach my $i (@b) {
		if ( exists $hash{$i} ) {
			print OUT $hash{$i}." ";
		}
		else {
			print "Phones $i doesn't exist in phone map\n";
			exit 1;
		}
	}
	print OUT "\n";
}
close IN;
close OUT;




