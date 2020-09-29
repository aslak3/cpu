start:		load.w r0,#0xf00f	; canary
		load.w r1,#0x4000	; start of video memory
		load.w r7,#0x200	; stack pointer
		load.w r2,#20

loop:		calljump printmessage	; call sub
		store.w SEVENSEG,r2
		dec r2
		jumpnz loop		; more printing
hop:		jump hop

printmessage:	pushquick (r7),r2
		pushquick (r7),r3
		load.w r2,#message	; get start of message in r2
messageloop:	load.bu r3,(r2)		; get this letter in r3
		test r3			; check letter for 0
		jumpz printmessageo	; zero? out we go
		or r3,#0x0f00		; or over the wob state
		store.w (r1),r3		; write letter
		incd r1			; inc video pointer
		inc r2
		store.w VGA_CURSOR_ADDR,r1
		branch messageloop	; back to the next letter
printmessageo:	popquick r3,(r7)
		popquick r2,(r7)
		return

message:	#str "123456789012345678901234567890123456789-\0"

