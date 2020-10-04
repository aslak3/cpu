#include "ascii.inc"
#align 2

; vga console routines

; sets up the cursoroffsets table: the start of each 80 coloumn row

initconsole:	load.bu r0,#60			; the number of rows
		load.w r1,#0x4000		; the running total
		load.w r2,#cursoroffsets	; the place to write to 
.loop:		store.w (r2),r1			; save this offset
		add r1,#160			; add on the width of a row
		incd r2				; move the write pointer
		dec r0				; dec the number of rows
		branchnz .loop			; done?
		clear r0
		store.w leftshifton,r0
		store.w rightshifton,r0
		load.bu r0,#0x0f
		store.w VGA_TEXT_DEFAULT_ATTR,r0
		return

; put the string in r1

putstring:	load.bu r0,(r1)			; load the next char
		inc r1				; move pointer along
		test r0				; looking for null
		branchz	putstringo		; found it?
		callbranch putchar		; put it on the screen
		branch putstring		; back for more
putstringo:	return

; put the char in r0, handling basic control codes
; r0: char in, r1: current row, r2: current col, r3: cursor position

putchar:	pushquick (r7),r1
		pushquick (r7),r2
		pushquick (r7),r3
		load.bu r1,cursorrow		; get the current row/2
		load.bu r2,cursorcol		; load the column
		compare r0,#ASC_CR		; cr?
		branchz putcharcr		; handle it
		compare r0,#ASC_LF		; cr?
		branchz putcharlf		; handle it
		compare r0,#ASC_BS		; bs?
		branchz putcharbs		; handle it
		load.w r3,(cursoroffsets,r1)	; get the start of this row
		add r3,r2			; add the column offset
		store.w (r3),r0			; save the char
		incd r2				; move coloumn counter
		compare r2,#160			; end of line?
		branchz newline			; wrap to next line
putcharo:	load.w r3,(cursoroffsets,r1)	; get the start of this row
		add r3,r2			; add the column offset
		store.w VGA_TEXT_CURSOR_ADDR,r3	; move the visiblecursor
		store.b cursorrow,r1		; save the row
		store.b cursorcol,r2		; save the col
		popquick r3,(r7)
		popquick r2,(r7)
		popquick r1,(r7)
		return
putcharcr:	incd r1				; down one row
		branch putcharo
putcharlf:	clear r2			; back to left margin
		branch putcharo
putcharbs:	decd r2
		branchnz putcharo
		decd r1
		load.bu r2,#(80*2)-2
		branch putcharo
newline:	clear r2
		incd r1
		branch putcharo

; get the string into r1

getstring:	pushquick (r7),r2
		clear r2
getstringtop:	callbranch getchar		; get a char in r0
		compare r0,#ASC_CR		; cr?
		branchz getstringo		; yes or no
		compare r0,#ASC_BS
		branchz getstringbs
		store.b (r1),r0			; save the char otherwise
		inc r1				; move pointer onward
		inc r2
		callbranch putchar		; echo it
		branch getstringtop		; back for more
getstringo:	clear r0			; adding a null					; move pointer along
		store.b (r1),r0			; save the null
		inc r1				; move pointer onward
		popquick r2,(r7)
		return
getstringbs:	test r2
		branchz getstringtop
		dec r1
		dec r2
		clear r0
		store.b (r1),r0
		load.bu r0,#ASC_BS
		calljump putchar
		load.bu r0,#ASC_SP
		calljump putchar
		load.bu r0,#ASC_BS
		calljump putchar
		branch getstringtop

; get a character in r0

getchar:	pushquick (r7),r1
		pushquick (r7),r2
getchartop:	calljump getbyte
		compare r0,#0xf0		; compare against break
		branchz dobreak			; yes/no

		compare r0,#KEY_L_SHIFT
		branchz leftshiftdown
		compare r0,#KEY_R_SHIFT
		branchz rightshiftdown

		load.w r1,leftshifton
		load.w r2,rightshifton
		add r1,r2
		test r1
		branchnz shifting
		load.bu r0,(scancodes,r0)	; load the ascii
		branch getcharo

dobreak:	calljump getbyte
		compare r0,#KEY_L_SHIFT
		branchz leftshiftup
		compare r0,#KEY_R_SHIFT
		branchz rightshiftup
		branch getchartop		; back for more

shifting:	load.bu r0,(shiftscancodes,r0)

getcharo:	popquick r2,(r7)
		popquick r1,(r7)
		return

leftshiftup:	clear r0
		branch handlelshift
rightshiftup:	clear r0
		branch handlershift
leftshiftdown:	load.w r0,#1
		branch handlelshift
rightshiftdown:	load.w r0,#1
		branch handlershift
handlelshift:	store.w leftshifton,r0
		branch getchartop
handlershift:	store.w rightshifton,r0
		branch getchartop

; get a byte in r0

getbyte:	load.bu r0,PS2_STATUS		; get from the status reg
		test r0				; nothing?
		jumpz getbyte			; keep waiting....
		load.bu r0,PS2_SCANCODE		; get the scancode
		return

leftshifton:	#res 2
rightshifton:	#res 2

shiftscancodes:

; 0

		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "

; 1

		#str " "
		#str " " ; Alt
		#str " "
		#str " "
		#str " "
		#str "Q"
		#str "!"
		#str " "
		#str " "
		#str " "
		#str "Z"
		#str "S"
		#str "A"
		#str "W"
		#str " " ; "
		#str " "

; 2

		#str " "
		#str "C"
		#str "X"
		#str "D"
		#str "E"
		#str "$"
		#str "#"
		#str " "
		#str " "
		#str " "
		#str "V"
		#str "F"
		#str "T"
		#str "R"
		#str "5"
		#str " "

; 3

		#str " "
		#str "N"
		#str "B"
		#str "H"
		#str "G"
		#str "Y"
		#str "6"
		#str " "
		#str " "
		#str " "
		#str "M"
		#str "J"
		#str "U"
		#str "&"
		#str "*"
		#str " "
; 4

		#str " "
		#str "<"
		#str "K"
		#str "I"
		#str "O"
		#str ")"
		#str "("
		#str " "
		#str " "
		#str ">"
		#str "?"
		#str "L"
		#str ":"
		#str "P"
		#str "_"
		#str " "

; 5

		#str " "
		#str " "
		#str " " ; '
		#str " "
		#str "{"
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#d8 ASC_CR ; cr
		#str "}"
		#str " "
		#str " "
		#str " "
		#str " "

; 6

		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#d8 ASC_BS
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "

scancodes:

; 0

		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "

; 1

		#str " "
		#str " " ; Alt
		#str " "
		#str " "
		#str " "
		#str "q"
		#str "1"
		#str " "
		#str " "
		#str " "
		#str "z"
		#str "s"
		#str "a"
		#str "w"
		#str "2"
		#str " "

; 2

		#str " "
		#str "c"
		#str "x"
		#str "d"
		#str "e"
		#str "4"
		#str "3"
		#str " "
		#str " "
		#str " "
		#str "v"
		#str "f"
		#str "t"
		#str "r"
		#str "5"
		#str " "

; 3

		#str " "
		#str "n"
		#str "b"
		#str "h"
		#str "g"
		#str "y"
		#str "6"
		#str " "
		#str " "
		#str " "
		#str "m"
		#str "j"
		#str "u"
		#str "7"
		#str "8"
		#str " "
; 4

		#str " "
		#str ","
		#str "k"
		#str "i"
		#str "o"
		#str "0"
		#str "9"
		#str " "
		#str " "
		#str "."
		#str "/"
		#str "l"
		#str ";"
		#str "p"
		#str "-"
		#str " "

; 5

		#str " "
		#str " "
		#str "'"
		#str " "
		#str "["
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#d8 ASC_CR ; cr
		#str "]"
		#str " "
		#str " "
		#str " "
		#str " "

; 6

		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#d8 ASC_BS
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "
		#str " "


		#align 2

variables:

input:          #res 100

cursoroffsets:	#res 2*60
cursorrow:	#res 1
cursorcol:	#res 1		
