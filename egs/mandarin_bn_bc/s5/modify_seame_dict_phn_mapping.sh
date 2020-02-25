#!/usr/bin/env bash


. path.sh
. utils/parse_options.sh || exit 1;

set -e -o pipefail
seame_lex_dir=$1
gale_lex_dir=$2
seame_lex_new_dir=$3

# split into English and Chinese
awk '{print $1}' $seame_lex_dir/lexicon.txt | grep '[a-zA-Z]' > $seame_lex_dir/words-en.txt || exit 1;
awk '{print $1}' $seame_lex_dir/lexicon.txt | grep -v '[a-zA-Z]' > $seame_lex_dir/words-ch.txt || exit 1;

echo "--- Preparing SEAME English lexicon ..."
awk 'NR==FNR{words[$1];next} $1 in words{print $0}' $seame_lex_dir/words-en.txt $seame_lex_dir/lexicon.txt | \
  perl -e '
  open(MAPS, $ARGV[0]) or die("could not open map file");
  my %py2ph;
  foreach $line (<MAPS>) {
    @A = split(" ", $line);
    $py = shift(@A);
    $py2ph{$py} = [@A];
  }
  my @entry;
  while (<STDIN>) {
    @A = split(" ", $_);
    @entry = ();
    $W = uc shift(@A);
    push(@entry, $W);
    for($i = 0; $i < @A; $i++) {
      @phns = split("_", $A[$i]);
      my $phn = $phns[0];
      if (exists $py2ph{$phn}) { push(@entry, @{$py2ph{$phn}}); }
      else {push(@entry, $phn)};
    }
    print "@entry";
    print "\n";
  }
' $seame_lex_new_dir/sge_phn.map > $seame_lex_new_dir/lexicon-en.txt || exit 1;
awk 'NR==FNR{words[$1];next} $1 in words{print $0}' $seame_lex_dir/words-ch.txt $seame_lex_dir/lexicon.txt |\
	 sed 's/_man\|ge\|ger\|ga\|go//g' | sed 's/ib\|if/i/g' | sed 's/van/uan/g' | awk '{a=$2;for(i=3;i<=NF;++i){a=a$i}print $1" "a}' > $seame_lex_dir/lexicon-ch.txt
cat $seame_lex_dir/lexicon-ch.txt | tr [:lower:] [:upper:] | grep -v 'M2' | grep -v 'M4' | utils/pinyin_map.pl conf/pinyin2cmu > $seame_lex_new_dir/lexicon-ch.txt

# combine English and Chinese lexicons
cat $seame_lex_new_dir/lexicon-en.txt $seame_lex_new_dir/lexicon-ch.txt | awk 'NF>1' | grep -v "<" |\
  sort -u > $seame_lex_new_dir/lexicon1.txt || exit 1;

cat $seame_lex_new_dir/lexicon1.txt | awk '{ for(n=2;n<=NF;n++){ phones[$n] = 1; }} END{for (p in phones) print p;}'| \
  sort -u |\
  perl -e '
  my %ph_cl;
  while (<STDIN>) {
    $phone = $_;
    chomp($phone);
    chomp($_);
    $phone =~ s:([A-Z]+)[0-9]:$1:;
    if (exists $ph_cl{$phone}) { push(@{$ph_cl{$phone}}, $_)  }
    else { $ph_cl{$phone} = [$_]; }
  }
  foreach $key ( keys %ph_cl ) {
     print "@{ $ph_cl{$key} }\n"
  }
  ' | sort -k1 > $seame_lex_new_dir/nonsilence_phones.txt  || exit 1;

( echo SIL; echo SPN; echo NSN; ) > $seame_lex_new_dir/silence_phones.txt

echo SIL > $seame_lex_new_dir/optional_silence.txt

# No "extra questions" in the input to this setup, as we don't
# have stress or tone

cat $seame_lex_new_dir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $seame_lex_new_dir/extra_questions.txt || exit 1;
cat $seame_lex_new_dir/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
 >> $seame_lex_new_dir/extra_questions.txt || exit 1;

# Add to the lexicon the silences, noises etc.
(echo '<V-NOISE> SPN'; echo '<NOISE> NSN'; echo '<UNK> SPN' ) | \
 cat - $seame_lex_new_dir/lexicon1.txt  > $seame_lex_new_dir/lexicon.txt || exit 1;

echo "$0: Mandarin dict preparation succeeded"
exit 0;
