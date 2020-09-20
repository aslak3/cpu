		load.w r0,#0xf00f		; canary - r0 is a bomb
		load.w r7,#0x200		; stack pointer(!)
		callbranch outter		; call the outter sub
hop:		branch hop			; on return, hop

outter:		calljump start			; call the inner
		return				; back to "main"

start:		clear r5			; the running total
		load.w r1,(foo+2,r5)		; initial value
		load.w r3,#0			; destination counter
		load.w r4,length		; space for our fibs
		pushmulti (r7),R0+R1+R2+R3	; test for pushmulti
		pushquick (r7),r4		; test for pushquick
		clear r0			; clear everything
		clear r1			; ...
		clear r2			; ...
		clear r3			; ...
		clear r4			; ...
		popquick r4,(r7)		; pop everything back
		popmulti R0+R1+R2+R3,(r7)	; ...
loop:		copy r2,r1			; copy the last written value
		add r1,r5			; accumulate
		branchc done			; overflow? out
		copy r5,r2			; copy it back over the running total
		store.w (fib,r3),r1  		; save it in fib table using dest counter
		incd r3				; increment alternative
		sub r4,#1			; decrement the space for fibs counter
		branchnz loop			; back if we have more room
done:		load.w r5,#0x2a2a		; just so we can test store
		store.w 0xc0,r5			; ...
		load.w r5,#0xaa55		; and storer
		load.w r1,#0x00c2		; ...
		store.w (r1),r5			; ...
foo:		return				; finished inner sub
		#d16 0x1			; initial value
length:		#d16 16				; and the length (words)

fib:
