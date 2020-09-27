start:		load.w r0,#0xcafe
loop:		store.w SEVENSEG,r0
		load.w r1,#0x10
delay:		dec r1
		jumpnz delay
		inc r0
		jump loop
