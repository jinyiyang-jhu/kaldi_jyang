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
    $tmp =~ s:Ｂ:B:g;
    $tmp =~ s:Ｋ:K:g;
    $tmp =~ s:Ｄ:D:g;
    $tmp =~ s:Ｎ:D:g;
    $tmp =~ s:Ｗ:W:g;
    $tmp =~ s:Ｇ:G:g;
    $tmp =~ s:Ｓ:S:g;
    $tmp =~ s:Ｔ:T:g;
    $tmp =~ s:Ｖ:V:g;
    $tmp =~ s:％::g;
    $tmp =~ s:Ⅱ::g;
    $tmp =~ s:＋::g;
    $tmp =~ s:－::g;
    $tmp =~ s:．::g;
    $tmp =~ s:０:0:g;
    $tmp =~ s:１:1:g;
    $tmp =~ s:２:2:g;
    $tmp =~ s:３:3:g;
    $tmp =~ s:４:4:g;
    $tmp =~ s:５:5:g;
    $tmp =~ s:６:6:g;
    $tmp =~ s:７:7:g;
    $tmp =~ s:８:8:g;
    $tmp =~ s:９:9:g;
    $tmp =~ s:；::g;
    $tmp =~ s:＜::g;
    $tmp =~ s:＞::g;
    $tmp =~ s:　::g;
    $tmp =~ s:、::g;
    $tmp =~ s:】::g;
    $tmp =~ s:·::g;
    $tmp =~ s:〉::g;
    $tmp =~ s:〈::g;
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
    $tmp =~ s:‰::g;
    $tmp =~ s:—::g;
    $tmp =~ s:○::g;
    $tmp =~ s:,::g;
    $tmp =~ s:・::g;
    $tmp =~ s:;::g;
    $tmp =~ s:\:::g;
    $tmp =~ s:\(::g;
    $tmp =~ s:\)::g;
    $tmp =~ s:\?::g;
    $tmp =~ s:□::g;
    $tmp =~ s: ::g;
    $tmp =~ s:＂::g;
    $tmp =~ s:＃::g;
    $tmp =~ s:＊::g;
    $tmp =~ s:／::g;
    $tmp =~ s:Ｅ::g;
    $tmp =~ s:Ｈ::g;
    $tmp =~ s:Ｍ::g;
    $tmp =~ s:Ｘ::g;
    $tmp =~ s:［::g;
    $tmp =~ s:］::g;
    $tmp =~ s:～::g;
    $tmp =~ s:￣::g;
    $tmp =~ s:￥::g;
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
