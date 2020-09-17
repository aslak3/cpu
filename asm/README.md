# Assembly files

The assembler currently used is CustomASM
(https://github.com/hlorenzi/customasm). This is a pretty neat assembler
implemented in Rust. A simple config (cpudef.inc) describes how mnemonics
map to instruction bitpatterns which make up the opcode and parameters.

Because customasm currently does not deal properly with the case where the
addressable unit size is different to the instruction width (8 vs 16 bits)
some scripts have been written to munge data into the needed formats:

hex2array.pl : writes out the guts of a 128 word VHDL array, for pasting
into the CPU test bench
hex2mif.pl : writes out a 128 word MIF file for including in the FPGA design

The test programs written so far are either run within the CPU testbench or
they are included in an FPGA design, which includes additional entities not
currently included in this repo.