#!/usr/bin/perl

use File::Find 'find';
use File::Basename;
use Cwd;

if (@ARGV < 1){
    print STDERR "Usage: input1_directory\n" .
    "directory could be multiple level\n";
    exit(1);
}

$dir=shift @ARGV;
open(W, ">$dir/wav.scp") || die "Unable to write under $dir";
my %wordlist;
my @files;

find(sub{push @files, $File::Find::name if -f and /\.wav$/i;}, $dir);

$dir = getcwd;
foreach my $file (@files){
    $fname = basename($file);
    print W $fname." ".$dir."/".$file."\n";
}

close W;

