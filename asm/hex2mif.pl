#!/usr/bin/perl
#
# Convert a 4096 word hex file to Altera Memory Image Format.
# See: https://www.mil.ufl.edu/4712/docs/mif_help.pdf
#
# STDIN->hex2mif.pl->STDOUT

my $offset = 0;

print "DEPTH = 4096;\n";
print "WIDTH = 16;\n";
print "ADDRESS_RADIX = DEC;\n";
print "DATA_RADIX = HEX;\n";
print "\n";
print "CONTENT\n";
print "BEGIN\n";

my $word;
while (sysread(STDIN, $word, 4))
{
	next unless ($word =~ /[0-9a-f]{4}/);
	printword($word);
}
while ($offset < 4096)
{
	printword("0000");
}
print "END;\n";

sub printword
{
	my ($word) = @_ ;
	if (($offset % 16) == 0) {
		print $offset . "\t: ";
	}
	print $word;
	if (($offset % 16) == 15) {
		print ";\n"; }
	else {
		print " ";
	}
	$offset++;
}
