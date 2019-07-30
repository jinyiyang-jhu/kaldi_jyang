#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter
# Copyright Chao Weng 

# normalizations for hkust trascript
# see the docs/trans-guidelines.pdf for details

while (<STDIN>) {
  @A = split(" ", $_);
  for ($n = 0; $n < @A; $n++) { 
    $a = $A[$n];
    $tmp = $a;
    $tmp =~ s:Ａ:A:g;
    $tmp =~ s:Ｄ:D:g;
    $tmp =~ s:Ｎ:D:g;
    $tmp =~ s:Ⅱ::g;
    $tmp =~ s:　::g;
    $tmp =~ s:、::g;
    $tmp =~ s:】::g;
    $tmp =~ s:·::g;
    $tmp =~ s:《::g;
    $tmp =~ s:》::g;
    $tmp =~ s:"::g;
    $tmp =~ s:‘::g;
    $tmp =~ s:’::g;
    $tmp =~ s:“::g;
    $tmp =~ s:”::g;
    $tmp =~ s:：::g;
    $tmp =~ s:（::g;
    $tmp =~ s:）::g;
    $tmp =~ s:…::g;
    $tmp =~ s:!::g;
    $tmp =~ s:\?::g;
    $tmp =~ s:-::g;
    $tmp =~ s:@::g;
    if ($tmp =~ /[^.]{0,}\.+/) {$tmp =~ s:\.:点:g;}
    if ($tmp =~ /？/) { $tmp =~ s:？::g; }
    if ($tmp =~ /。/) { $tmp =~ s:。::g; }
    if ($tmp =~ /！/) { $tmp =~ s:！::g; }
    if ($tmp =~ /，/) { $tmp =~ s:，::g; }
    if ($tmp =~ /\~[A-Z]/) { $tmp =~ s:\~([A-Z])::; }
    if ($tmp =~ /\S%/) { $tmp =~ s:%::; }
    if ($tmp =~ /\S%/) { $tmp =~ s:%::; }
    if ($tmp =~ /[a-zA-Z]/) {$tmp=uc($tmp);} 
    print "$tmp "; 
  }
  print "\n"; 
}
