#!/usr/bin/perl
#
#
$word = shift @ARGV;
$dict = shift @ARGV;
$phone = shift @ARGV;


open(W,"<$word");
open(D,"<$dict");
open(P,">$phone");


while (<D>) {
	chomp;
	my @a = split /\s+/,$_;
	my $w = shift @a;
	my $s = join " ", @a;
	$hash_dict{$w} = $s;
}
close;

while (<W>) {
	chomp;
	my @b = split /\s+/, $_;
	my $utt = shift @b;
	print P $utt." ";
	foreach my $k ( @b) {
		if ( exists $hash_dict{$k} ) {
			print P $hash_dict{$k}." ";
		}
		else {
			print "Word $k not in dictionary\n";
			exit 1;
		}
	}
	print P "\n";
}
close W;
close P;
	      	
