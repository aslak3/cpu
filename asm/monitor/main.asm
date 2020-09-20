start:		load.w r7,#0x2000

		load.w r0,#0x4321
		store.w SEVENSEG,r0

		callbranch initconsole

loop:		load.w r1,#prompt
		callbranch putstring
		load.w r1,#input
		callbranch getstring
		load.w r1,#youtyped
		callbranch putstring
		load.w r1,#input
		callbranch putstring
		load.w r1,#crlf
		callbranch putstring
		branch loop

prompt:		#str "Oonitor: > \0"
youtyped:	#str "You typed: \0"
crlf:		#str "\r\n\0"
input:		#res 100

#include "console.asm"
