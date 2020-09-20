start:		load.w r0,#0xbeef
loop:		store.w SEVENSEG,r0
;		load.w r1,#0xf000
;delay:		dec r1
;		branchnz delay
;		inc r0
;		branch loop
hop:		jump hop
