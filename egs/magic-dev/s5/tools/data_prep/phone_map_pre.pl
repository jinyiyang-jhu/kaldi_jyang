#!/usr/bin/perl
#
use Data::Dumper qw(Dumper);

$phone_class_int= shift @ARGV; #phone_class.int
$class_to_phonemes= shift @ARGV; #class_sys_to_phone_int.map, not root int
$class_id_to_phonemes_id = shift @ARGV;#class_int_to_phone_int.map

open(CLASS,$phone_class_int);
open(SYS,$class_to_phonemes);
open(OUT,">$class_id_to_phonemes_id");

while ( <CLASS>)
{
 chomp;
 @class=split/\s+/,$_;
 $hashclass{$class[0]}=$class[1];
}
close CLASS;

$initial="";
$id="";
$sys="";
while (<SYS>)
{
 chomp;
 @sysline=split/\s+/,$_;
 $sys=shift @sysline;
# unshift @sysline,$hashclass{$sys};
 $id_seq=join " ",@sysline;
 #$id_seq=" ".$id_seq;
 if (exists $hashphoneme{$hashclass{$sys}} )
 {
   $hashphoneme{$hashclass{$sys}}.=" $id_seq";
 }
 else
 {
   $hashphoneme{$hashclass{$sys}}=$id_seq;
 }
 #$hashphoneme{$hashclass{$sys}}=$initial;
 #print OUT $outline."\n";
}
close SYS;

@arrayhashphonemes=keys %hashphoneme;
@sorted=sort { $a <=> $b } @arrayhashphonemes;
foreach $key (@sorted)
{
 print OUT $key." ".$hashphoneme{$key}."\n";
 #print $hashphoneme{$key}."\n";
 print $key."\n";
}
close OUT;
