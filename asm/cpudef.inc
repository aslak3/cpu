R0=1
R1=2
R2=4
R3=8
R4=16
R5=32
R6=64
R7=128

#cpudef
{
	#bits 8

	#tokendef reg
	{
		r0 = 0
		r1 = 1
		r2 = 2
		r3 = 3
		r4 = 4
		r5 = 5
		r6 = 6
		r7 = 7
	}
	#tokendef loadtype
	{
		w = 0b00
		bu = 0b10
		bs = 0b11
	}
	#tokendef storetype
	{
		w = 0b00
		b = 0b10
	}
	#tokendef condition
	{
		nz = 0b010000
		z = 0b010010
		nc = 0b100000
		c = 0b100100
		nn = 0b001000
		n = 0b001001
	}
	#tokendef twoargalu
	{
		add = 0x0
		addc = 0x1
		sub = 0x2
		subc = 0x3
		and = 0x4
		or = 0x5
		xor = 0x6
		copy = 0x7
		compare = 0x8
		bit = 0x9
	}
	#tokendef oneargalu
	{
		inc = 0x0
		dec = 0x1
		incd = 0x2
		decd = 0x3
		not = 0x4
		shiftleft = 0x5
		shiftright = 0x6
		negate = 0x7
		swap = 0x8
		test = 0x9
	}

	nop -> 0x0000

	load.{width:loadtype} {dst:reg}, #{value} ->
		0b000100 @ width[1:0] @ 0b00 @ 0b000 @ dst[2:0] @ value[15:0]

	load.{width:loadtype} {dst:reg}, {addr} ->
		0b001000 @ width[1:0] @ 0b00 @ 0b000 @ dst[2:0] @ addr[15:0]
	load.{width:loadtype} {dst:reg}, ({src:reg}) ->
		0b001010 @ width[1:0] @ 0b00 @ src[2:0] @ dst[2:0]
	load.{width:loadtype} {dst:reg}, ({offset},{src:reg}) ->
		0b011010 @ width[1:0] @ 0b00 @ src[2:0] @ dst[2:0] @ offset[15:0]

	clear {dst:reg} ->
		0b001100 @ 0b0000 @ 0b000 @ dst[2:0]

	store.{width:storetype} {addr}, {src:reg} ->
		0b001001 @ width[1:0] @ 0b00 @ 0b000 @ src[2:0] @ addr[15:0]
	store.{width:storetype} ({dst:reg}), {src:reg} ->
		0b001011 @ width[1:0] @ 0b00 @ dst[2:0] @ src[2:0]
	store.{width:storetype} ({offset},{dst:reg}), {src:reg} ->
		0b011011 @ width[1:0] @ 0b00 @ dst[2:0] @ src[2:0] @ offset[15:0]

	jump {target} ->
		0b000010 @ 0b0000 @ 0b000000 @ target[15:0]
	jump{test:condition} {target} ->
		0b000010 @ 0b0000 @ test[5:0] @ target[15:0]
	branch {target} ->
		0b000011 @ 0b0 @0b000000000 @ { target - pc - 2 }[15:0]
	branch{test:condition} {target} ->
		0b000011 @ 0b0000 @ test[5:0] @ { target - pc - 2 }[15:0]

	{aluop:twoargalu} {dst:reg}, {operand:reg} ->
		0b001110 @ aluop[3:0] @ operand[2:0] @ dst[2:0]
	{aluop:twoargalu} {dst:reg}, #{value} ->
		0b001111 @ aluop[3:0] @ 0b000 @ dst[2:0] @ value[15:0]
	{aluop:oneargalu} {dst:reg} ->
		0b000001 @ aluop[3:0] @ 0b000 @ dst[2:0]

	; 0b111 - use r7
	calljump {target} ->
		0b010000 @ 0b0000 @ 0b111 @ 0b111 @ target[15:0]
	callbranch {target} ->
		0b010001 @ 0b0000 @ 0b111 @ 0b111 @ { target - pc - 2 }[15:0]
	return ->
		0b010010 @ 0b0000 @ 0b111 @ 0b111

	pushquick ({dst:reg}), {src:reg} ->
		0b010100 @ 0b0000 @ dst[2:0] @ src[2:0]
	popquick {dst:reg}, ({src:reg}) ->
		0b010101 @ 0b0000 @ src[2:0] @ dst[2:0]
	pushmulti ({dst:reg}), {src} ->
		0b010110 @ 0b0000 @ dst[2:0] @ 0b000 @ 0b00000000 @ src[7:0]
	popmulti {dstregs:u8}, ({src:reg}) ->
		0b010111 @ 0b0000 @ src[2:0] @ 0b000 @ 0b00000000 @ dstregs[7:0]
}
