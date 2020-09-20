#include "ascii.inc"
#align 2

; vga console routines
; hardware: swap char word so index is on LSB, attribute is on MSB, make
; attribute=0 use default

; sets up the cursoroffsets table: the start of each 80 coloumn row

initconsole:	load.bu r0,#60			; the number of rows
		load.w r1,#0x8000		; the running total
		load.w r2,#cursoroffsets	; the place to write to 
.loop:		store.w (r2),r1			; save this offset
		add r1,#160			; add on the width of a row
		incd r2				; move the write pointer
		dec r0				; dec the number of rows
		branchnz .loop			; done?
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

putchar:	pushmulti (r7),R1+R2+R3
		load.bu r1,cursorrow		; get the current row/2
		load.bu r2,cursorcol		; load the column
		compare r0,#ASC_CR		; cr?
		branchz putcharcr		; handle it
		compare r0,#ASC_LF		; cr?
		branchz putcharlf		; handle it
		load.w r3,(cursoroffsets,r1)	; get the start of this row
		add r3,r2			; add the column offset
		store.w (r3),r0			; save the char
		incd r2				; move coloumn counter
		compare r2,#160			; end of line?
		branchz newline			; wrap to next line
putcharo:	load.w r3,(cursoroffsets,r1)	; get the start of this row
		add r3,r2			; add the column offset
		store.w CURSOR_POS,r3		; move the visiblecursor
		store.b cursorrow,r1		; save the row
		store.b cursorcol,r2		; save the col
		popmulti R1+R2+R3,(r7)
		return
putcharcr:	incd r1				; down one row
		branch putcharo
putcharlf:	clear r2			; back to left margin
		branch putcharo
newline:	clear r2
		incd r1
		branch putcharo

; get the string into r1

getstring:	callbranch getchar		; get a char in r0
		callbranch putchar		; echo it
		compare r0,#ASC_CR		; cr?
		branchz getstringo		; yes or no
		store.b (r1),r0			; save the char otherwise
		inc r1				; move pointer onward
		branch getstring		; back for more
getstringo:	clear r0			; adding a null					; move pointer along
		store.b (r1),r0			; save the null
		inc r1				; move pointer onward
		return

; get the char in r0

getchar:	pushquick (r7),r1
		clear r1			; clear the break flag
		load.bu r0,PS2_STATUS		; get from the status reg
		test r0				; nothing?
		jumpz getchar			; keep waiting....
		load.bu r0,PS2_SCANCODE		; get the scancode
		compare r0,#0xf0		; compare against break
		branchz break			; yes/no
		test r1				; are we handling a break?
		branchnz clearbreak		; make it ignore it once
		load.bu r0,(scancodes,r0)	; load the ascii
		popquick r1,(r7)
		return
clearbreak:	clear r1			; clear breaked flag
		branch getchar			; back for more
break:		load.w r1,#1			; set break flag
		branch getchar

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
		#str "Q"
		#str "1"
		#str " "
		#str " "
		#str " "
		#str "Z"
		#str "S"
		#str "A"
		#str "W"
		#str "2"
		#str " "

; 2

		#str " "
		#str "C"
		#str "X"
		#str "D"
		#str "E"
		#str "4"
		#str "3"
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
		#str "7"
		#str "8"
		#str " "
; 4

		#str " "
		#str ","
		#str "K"
		#str "I"
		#str "O"
		#str "0"
		#str "9"
		#str " "
		#str " "
		#str "."
		#str "/"
		#str "L"
		#str ";"
		#str "P"
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
		#str "\n"
		#str "]"
		#str " "
		#str " "
		#str " "
		#str " "


; variables

#align 2

cursoroffsets:	#res 2*60
cursorrow:	#res 1
cursorcol:	#res 1		
