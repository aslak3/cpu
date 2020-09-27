#!/usr/bin/perl
#
# Convert a 4096 word hex file to Intel Hex format.
#
# STDIN->hex2intel.pl->STDOUT

my $offset = 0;

my $word;
while (sysread(STDIN, $word, 4))
{
	next unless ($word =~ /[0-9a-f]{4}/);
	printword(uc $word);
}
while ($offset < 4096)
{
	printword("0000");
}
print ":00000001FF\n";

sub printword
{
	my ($word) = @_ ;
	my $hex = hex $word;
	print ":02";
	my $checksum = 2;

	printf("%04X", $offset);
	$checksum += ($offset % 256 + int($offset / 256)) % 256;
	print "00";

	printf("%04X", $hex);
	$checksum += ($hex % 256 + int ($hex / 256)) % 256;
	$checksum = (256 - $checksum) % 256;

	printf("%02X\n", $checksum);
	$offset++;
}
