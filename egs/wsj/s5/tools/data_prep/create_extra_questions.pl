#!/usr/bin/perl

use File::Basename;

if (@ARGV < 1){
    print STDERR "Usage: create_extra_questions.pl non_silence_phone.txt\n" .
    "output: extra_questions.txt under same dir as input\n";
    exit(1);
}

$input = shift(@ARGV);
$dirname = dirname($input);
$output = "$dirname/extra_questions.txt";

open(W, ">$output") || die "Unable to write output in $dir\n";
print W "sil\n";

my @special_list = ("1", "2", "3", "4", "_en");

my %a = ();
foreach my $symbol (@special_list){
    $a{$symbol} = ();
}

$a{"none"} = ();

open(I, "<$input") || die "Unable to open file $input\n";
while(<I>){
    chomp($phone = $_);
    $flag = 0;
    foreach my $symbol (@special_list){
        if ($phone =~ /$symbol/){
            push @{$a{$symbol}}, $phone;
            $flag = 1;
            }
    }
    if ($flag == 0){
        push @{$a{"none"}}, $phone;
        }
}
close I;

foreach my $key (sort (keys %a)){
    $string = join " ", sort(@{$a{$key}});
    print W $string."\n";
    }
close W;




