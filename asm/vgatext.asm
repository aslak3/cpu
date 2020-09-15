start:		load.w r0,#0xf00f	; canary
		load.w r1,#0x8000	; start of video memory
		load.w r7,#0x80		; stack pointer

loop:		calljump printmessage	; call sub
		load.w r2,#0x8000	; delay
delay:		dec r2			; dec delay
		jumpnz delay		; more delay
		jump loop		; more printing

printmessage:	load.w r2,#message	; get start of message in r2
messageloop:	load.bu r3,(r2)		; get this letter in r3
		test r3			; check letter for 0
		jumpz printmessageo	; zero? out we go
		swap r3			; move letter to high half
		or r3,#0x0f		; attribute: white on black
		inc r2			; next letter
		store.w (r1),r3		; write letter
		incd r1			; inc video pointer
		store.w 0x200,r1	; put the address-8000 on the lcd
		branch messageloop	; back to the next letter
printmessageo:	return

message:	#str "Hello, World!  \0"

