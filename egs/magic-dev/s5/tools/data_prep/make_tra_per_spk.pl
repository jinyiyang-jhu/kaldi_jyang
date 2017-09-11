#!/usr/bin/perl
#
#
$spk2utt = $ARGV[0];
$tra = $ARGV[1];
$output = $ARGV[2];

open(SPK,"<$spk2utt") || die "Input: spk2utt, tra_file, output_tra";
open(TRA,"<$tra");
open(OUT,">$output");

while (<SPK>)
{
 chomp;
 @array_spk = ();
 @array_spk = split/\s+/,$_;
 $spk = shift @array_spk;
 foreach $key (@array_spk)
 {
  $hash_spk{$key} = $spk;
  }
}
close SPK;

%hash_flag = ();
while (<TRA>)
{
	chomp;
	@array_tra = ();
	@array_tra = split /\s+/,$_;
	$utt = shift @array_tra;
	$string = join " ", @array_tra;
	if ( exists $hash_spk{$utt} )
	{
		if ( exists $hash_flag{$hash_spk{$utt}} )
		{
			$hash_flag{$hash_spk{$utt}}.= " $string";
		}
		else
		{
			$hash_flag{$hash_spk{$utt}} = $string;
		}
	}
	else
	{
		print "Utt $utt doesn't have matching spk\n";
		exit 1;
	}
}
close TRA;

foreach my $key (sort keys %hash_flag)
{
	print OUT $key." ".$hash_flag{$key}."\n";
}

close OUT;

