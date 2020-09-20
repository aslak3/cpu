#!/usr/bin/perl
#
# Convert a 128 word hex file to the guts of a VHDL array
#
# STDIN->hex2array.pl->STDOUT

my $offset = 0;

my $word;

print <<END
; Machine generated; do not try to edit!
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_RAM is
	type MEM is ARRAY (0 to 4095) of STD_LOGIC_VECTOR (15 downto 0);
	signal RAM : MEM := (
END
;

while (sysread(STDIN, $word, 4))
{
	next unless ($word =~ /[0-9a-f]{4}/);
	printword($word);
}
while ($offset < 4096)
{
	printword("0000");
}
print <<END
	);
end package;
END
;

sub printword
{
	my ($word) = @_;
	print "\t\tx\"" . $word . "\"";
	if ($offset != 4095) {
		print ",";
	}
	print "\n";
	$offset++;
}
