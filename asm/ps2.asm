		load.w r5,#0			; cursor offset
		load.w r6,#0x8000		; video writing offset
		load.w r7,#0x100		; stack pointer
		clear r1			; break found flag

		load.w r0,#prompt
		callbranch printmessage

mainloop:	load.bu r0,0x600		; get from the status reg
		test r0				; nothing?
		jumpz mainloop			; keep waiting....
		load.bu r0,0x601		; get the scancode
		compare r0,#0xf0		; compare against break
		branchz break			; yes/no
		test r1				; are we handling a break?
		branchnz clearbreak		; make it ignore it once
		load.bu r0,(scancodes,r0)	; load the ascii
		swap r0				; swap attr and char
		or r0,#0x0f			; white on black
		store.w (r6),r0			; write it
		inc r5				; move to next cursor pos
		store.w 0x304,r5		; and write it
		incd r6				; move to next char square
clearbreak:	clear r1			; clear breaked flag
		branch mainloop			; back for more
break:		load.w r1,#1			; set break flag
		branch mainloop

; print the message in r0

printmessage:	pushquick (r7),r1		; save char register
.loop:		load.bu r1,(r0)			; get the char to write
		inc r0				; next char to print
		test r1				; end?
		branchz printmessageo		; yes/no
		swap r1				; swap the char and attr
		or r1,#0x0f			; white on black
		store.w (r6),r1			; save it to the vram
		incd r6				; move to next char
		inc r5				; cursor counter
		store.w 0x304,r5		; move the cursor
		branch .loop			; back for more
printmessageo:	popquick r1,(r7)		; restore reg
		return

prompt:		#str "Hello! Type something: \0"

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
