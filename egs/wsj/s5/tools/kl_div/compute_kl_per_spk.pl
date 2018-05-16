#!/usr/bin/perl
#
#
$kl_per_utt = $ARGV[0]; #KL_sum_per_utt_sys_*.txt file
#$kl_per_utt  = "./KL_divergence/pnorm_clean/test_eval92_noise_harish_street_unigram_avrg_srilm_vs_trigram_window_0_medfilt_flag_11/KL_sys_medfilt_11.txt";
$kl_per_spk = $ARGV[1];
#$kl_per_spk = "./performance_monitor/test_eval92_noise_harish_street/KL_avrg_win_0_sys_medfilt_11_spk.txt";
$digit_of_spk = $ARGV[2];

open(IN,"<$kl_per_utt") || die "Can't open file $0 !";
open(OUT, ">$kl_per_spk");

while (<IN>) {
	chomp;
	@array = split /\s+/,$_;
	$utt_id = shift @array;
	$spk_id = substr $utt_id, 0, $digit_of_spk;
        my $frame = 0;	
	my $sum = 0;
	my $sum = shift @array;
	my $frame = shift @array;
        my @a = (); 
	if (exists $hash{$spk_id}) {
		$hash{$spk_id}[0] += $sum;
		$hash{$spk_id}[1] += $frame;

	}
	else {
	        @a = ($sum, $frame);
		$hash{$spk_id} =[ @a ];
	}
}

foreach $i ( sort keys %hash) {
	print OUT $i." ".$hash{$i}[0]/$hash{$i}[1]."\n";
}
close IN;
close OUT;

