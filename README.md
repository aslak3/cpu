# 16 bit processor in VHDL

This is a project for learning, which is pretty much useless except for anyone interested in how a trivial processor could be implemented. That said, I think it's cool.

This is also a work in progress.

# Summary of features

* 16 bit address and databuses
* 16 bit opcodes
* Some instructions (LOADI, STOREI, JUMPs, BRANCHes, ALUI) have one following operand
* 8 x 16 bit general purpose registers
* 16 bit Program Counter
* Load and store instructions operate either through a register or an immediate address
* Clear instruction
* Simple status bits: zero, negative, carry
* ALU operations are: add, add with carry, subtract, subtract with carry, increment, decrement, and, or, xor, not, shift left, shift right, copy, negation, compare
* ALU operations are of the form DEST <= DEST op OPERAND, or DEST <= op DEST, where both are registers.
* Conditional jumps: always, on each flag set and on each flag clear
* Nop instruction
* No microcode: a coded state machine is used

# Additional limitations

* No interrupts
* No byte wide operations at least initially (the ALU has INCD/DECD instructions which will someday fascilitate byte/word increments)

# TODO

* A "good" custom cross assembler
* Proper testbench for the CPU controller
* Eliminate empty states
* Add more instructions!
  - Bit test (non distructive and)
  - Relative addressing
  - ....
* Properly implement twos complement
  - Arithmatic shifts
* Better status bits: not currently settable, nor are they changed on
anything other then an ALU instruction
* Hardware stack, subroutines

# Top level RTL diagram

![Top level RTL](docs/toplevel.png "Top level RTL")

# Opcode map (OUT OF DATE)

<table>
<tr>
<td width='10%'>Opcode</td>
<td width='5%'>15</td>
<td width='5%'>14</td>
<td width='5%'>13</td>
<td width='5%'>12</td>
<td width='5%'>11</td>
<td width='5%'>10</td>
<td width='5%'>9</td>
<td width='5%'>8</td>
<td width='5%'>7</td>
<td width='5%'>6</td>
<td width='5%'>5</td>
<td width='5%'>4</td>
<td width='5%'>3</td>
<td width='5%'>2</td>
<td width='5%'>1</td>
<td width='5%'>0</td>
<td width='10%'>Hex</td>
</tr>
<tr>
<td>NOP</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0000</td>
</tr>
<tr>
<td>JUMPA</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>-</td>
<td>0008</td>
</tr>
<tr>
<td>JUMPC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>000b</td>
</tr>
<tr>
<td>JUMPNC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>000a</td>
</tr>
<tr>
<td>JUMPZ</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>000d</td>
</tr>
<tr>
<td>JUMPNZ</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>000c</td>
</tr>
<tr>
<td>JUMPN</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>000f</td>
</tr>
<tr>
<td>JUMPNN</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>000e</td>
</tr>
<tr>
<td>LOADI</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td colspan='3'>dst reg</td>
<td>0010-0017</td>
</tr>
<tr>
<td>STOREI</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>src reg</td>
<td>0020-0027</td>
</tr>
<tr>
<td>LOADR</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td colspan='3'>src addr reg</td>
<td colspan='3'>dst reg</td>
<td>0040-007f</td>
</tr>
<tr>
<td>STORER</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td colspan='3'>dst addr reg</td>
<td colspan='3'>src reg</td>
<td>0080-00bf</td>
</tr>
<tr>
<td>ADD</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1000-103f</td>
</tr>
<tr>
<td>ADDC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1100-113f</td>
</tr>
<tr>
<td>SUB</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1200-123f</td>
</tr>
<tr>
<td>SUBC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1300-133f</td>
</tr>
<tr>
<td>INC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1400-143f</td>
</tr>
<tr>
<td>INCD</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1500-153f</td>
</tr>
<tr>
<td>DEC</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1600-163f</td>
</tr>
<tr>
<td>DECD</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1700-173f</td>
</tr>
<tr>
<td>AND</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1800-183f</td>
</tr>
<tr>
<td>OR</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1900-193f</td>
</tr>
<tr>
<td>XOR</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td colspan='3'>operand reg</td>
<td colspan='3'>dst reg</td>
<td>1a00-1a3f</td>
</tr>
<tr>
<td>NOT</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1b00-1b3f</td>
</tr>
<tr>
<td>LEFT</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1c00-1c3f</td>
</tr>
<tr>
<td>RIGHT</td>
<td>0</td>
<td>0</td>
<td>0</td>
<td>1</td>
<td>1</td>
<td>1</td>
<td>0</td>
<td>1</td>
<td>0</td>
<td>0</td>
<td colspan='3'>-</td>
<td colspan='3'>dst reg</td>
<td>1d00-1d3f</td>
</tr>
</table>
