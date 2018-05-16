#!/usr/bin/perl

use File::Find 'find';

if (@ARGV < 1){
    print STDERR "Usage: input1_directory\n" .
    "directory could be multiple level\n";
    exit(1);
}

$dir=shift @ARGV;
open(W, ">$dir/wordlist.txt") || die "Unable to write under $dir";
my %wordlist;
my @files;

find(sub{push @files, $File::Find::name if -f and /\.txt$/i;}, $dir);


foreach my $file (@files){
    open(F, "<$file");
    while(<F>){
        chomp;
        my @line = split /\s+/, $_;
        foreach my $word (@line){
            $wordlist{$word} = 0;
            }
        }
        close F;
}

foreach $key (sort keys(%wordlist)){
    print W "$key\n";
}
close W;

