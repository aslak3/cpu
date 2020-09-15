#!/usr/bin/perl
#
# Convert a 128 word hex file to the guts of a VHDL array
#
# STDIN->hex2array.pl->STDOUT

my $offset = 0;

my $word;
while (sysread(STDIN, $word, 4))
{
	next unless ($word =~ /[0-9a-f]{4}/);
	printword($word);
}
while ($offset < 128)
{
	printword("0000");
}

sub printword
{
	my ($word) = @_;
	print "x\"" . $word . "\"";
	if ($offset != 127) {
		print ",";
	}
	print "\n";
	$offset++;
}
