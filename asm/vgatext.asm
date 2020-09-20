start:		load.w r0,#0xf00f	; canary
		load.w r1,#0x8000	; start of video memory
		load.w r7,#0x80		; stack pointer

loop:		load.w r4,#0x0f00	; polarity of text
		load.w r2,#0x0002	; delay
delay:		load.w r3,BUTTON	; get button state
		test r3			; see if we pushed
		branchnz notpushed	; yes/no
		load.w r4,#0xf000	; yes: black on white
notpushed:	dec r2			; dec delay
		jumpnz delay		; more delay
		calljump printmessage	; call sub
		jump loop		; more printing

printmessage:	load.w r2,#message	; get start of message in r2
messageloop:	load.bu r3,(r2)		; get this letter in r3
		test r3			; check letter for 0
		jumpz printmessageo	; zero? out we go
		or r3,r4		; or over the wob state
		store.w (r1),r3		; write letter
		incd r1			; inc video pointer
		inc r2
		store.w SEVENSEG,r1	; put the address on the lcd
		branch messageloop	; back to the next letter
printmessageo:	return

message:	#str "123456789012345678901234567890123456789-\0"

