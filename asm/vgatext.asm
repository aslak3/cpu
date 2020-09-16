start:		load.w r0,#0xf00f	; canary
		load.w r1,#0x8000	; start of video memory
		load.w r7,#0x80		; stack pointer

loop:		load.bu r4,#0x0f
		load.w r2,#0x4000	; delay
delay:		load.w r3,#0x500
		load.w r3,(r3)
		test r3
		branchnz notpushed
		load.bu r4,#0xf0
notpushed:	dec r2			; dec delay
		jumpnz delay		; more delay
		calljump printmessage	; call sub
		jump loop		; more printing

printmessage:	load.w r2,#message	; get start of message in r2
messageloop:	load.bu r3,(r2)		; get this letter in r3
		test r3			; check letter for 0
		jumpz printmessageo	; zero? out we go
		swap r3			; move letter to high half
		or r3,r4		; attribute: white on black
		inc r2			; next letter
		store.w (r1),r3		; write letter
		incd r1			; inc video pointer
		store.w 0x200,r1	; put the address-8000 on the lcd
		branch messageloop	; back to the next letter
printmessageo:	return

message:	#str "Hello, World! 123456 \0"

