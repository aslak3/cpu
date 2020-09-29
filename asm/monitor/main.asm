start:		load.w r7,#0x2000

		load.w r0,#variables
		load.w r1,#0x8000-variables
		clear r2
clearloop:	store.w (r0),r2
		incd r0
		decd r1
		branchnz clearloop

		callbranch initconsole

loop:		load.w r1,#prompt
		callbranch putstring

		load.w r1,#input
		callbranch getstring
		load.w r1,#crlf
		callbranch putstring

		load.w r1,#youtyped
		callbranch putstring
		load.w r1,#input
		callbranch putstring
		load.w r1,#crlfcrlf
		callbranch putstring

		branch loop

prompt:		#str "Monitor: > \0"
youtyped:	#str "You typed: \0"
crlf:		#str "\r\n\0"
crlfcrlf:	#str "\r\n\r\n\0"

#include "console.asm"
