		load.w r0,#0xf00f		; canary - r0 is a bomb
		load.w r7,#0x80			; stack pointer(!)
		callbranch outter		; call the outter sub
hop:		branch hop			; on return, hop

outter:		calljump start			; call the inner
		return				; back to "main"

start:		clear r5			; the running total
		load.w r1,#foo			; r1 will be the intial value
		load.w r1,(2,r1)		; initial value
		load.w r3,#0			; destination counter
		load.w r4,#length		; space for our fibs
		load.w r4,(r4)			; load it
		pushquick (r7),r4
		clear r4
		popquick r4,(r7)
loop:		copy r2,r1			; copy the last written value
		add r1,r5			; accumulate
		branchc done			; overflow? out
		copy r5,r2			; copy it back over the running total
		store.w (fib,r3),r1  		; save it in fib table using dest counter
		incd r3				; increment alternative
		sub r4,#1			; decrement the space for fibs counter
		branchnz loop			; back if we have more room
done:		load.w r5,#0x2a2a		; just so we can test store
		store.w 0x0076,r5		; ...
		load.w r5,#0xaa55		; and storer
		load.w r1,#0x0074		; ...
		store.w (r1),r5			; ...
		jump hop
foo:		return				; finished inner sub
		#d16 0x1			; initial value
length:		#d16 8				; and the length (words)

fib:
