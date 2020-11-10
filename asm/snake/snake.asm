#include "snake.inc"

ORIGIN=0x4000
WIDTH=40
HEIGHT=30

start:		load.w r7,#0x2000		; stack pointer

		load.w r0,#1			; game mode
		store.w VGA_MODE,r0		; ...

		load.w r0,#0x8000-bss		; clear mem past start ...
		clear r1			; .. of variables
.clearloop:	decd r0				; double dec the counter
		store.w (bss,r0),r1		; clear the mem...
		test r0				; ... starting from the end
		branchnz .clearloop		; back for more?

		load.w r0,#lcdinitseq		; get the init sequence
		load.w r1,#LCD_CONTROL		; its going in control port
		callbranch lcdoutput		; write it out
		load.w r0,#lcdtitlemsg		; get the message
		load.w r1,#LCD_DATA		; its going in data port
		calljump lcdoutput		; do a calljump just for fun

		load.w r0,#1			; breakpoint shows a number
		callbranch breakpoint		; and waits for a button

		callbranch randominit		; setup the prng
newgame:	load.w r0,#600			; starting speed of snake
		store.w movementdelay,r0	; ...

		load.bu r0,#2			; two squares by default
		store.b snakelength,r0		; for the length
		clear r0			; reset head position
		store.b headpos,r0		; snake starts at top of tab

		load.bu r0,#3			; three lives by default
		store.b lives,r0		; not nine as you are not cat

newlife:	callbranch drawplayarea		; show the border and lives

		load.w r0,#2
		callbranch breakpoint

		callbranch placenewfood		; and we need food

		load.w r0,#3
		callbranch breakpoint

		load.bu r0,#15			; start pos
		load.w r1,#0x100		; 256 positions
.rowloop:	dec r1				; filling backwards
		store.b (rowsnake,r1),r0	; write this everywhere
		test r1				; did we get to the end?
		branchnz .rowloop

		load.w r0,#4
		callbranch breakpoint

		load.bu r0,#20			; start pos
		load.w r1,#0x100		; 256 positions
.colloop:	dec r1				; filling backwards
		store.b (colsnake,r1),r0	; write this everywhere
		test r1				; did we get to the end?
		branchnz .colloop		; get more

		load.w r0,#5
		callbranch breakpoint

		clear r0			; right,down,left.up
		store.b snakedirection,r0	; snake starts moving right
		load.bu r0,#1			; +1 for horiz moving
		store.b coldirection,r0		; ..
		clear r0			; not going up/down
		store.b rowdirection,r0		; right

		load.w r0,#6
		callbranch breakpoint

mainloop:	load.bu r1,headpos		; current head pos
		load.bu r0,snakelength		; get the length
		sub r1,r0			; subtract length
		and r1,#0xff			; wrap it 0->255
		load.bu r0,#TILE_BLANK		; blanking the end
		callbranch drawsnakepart	; blank the old tail

		load.w r0,#7
		callbranch breakpoint

		load.bu r1,headpos		; drawing from current head
		load.bu r0,#TILE_BODY		; snake will be headless
		callbranch drawsnakepart	; poor snake

		load.w r0,#8
		callbranch breakpoint

		callbranch steersnake		; adjust col/rowdirection
		callbranch movesnake		; adjust the col/rowsnake

		callbranch docollision		; colision handler
		test r0				; see if we hit something
		branchnz death			; dead? handle the death

		load.bu r1,headpos		; get new headpos
		load.bu r0,snakedirection	; what way are we moving?
		add r0,#TILE_HEAD_RIGHT		; offset into the heads
		callbranch drawsnakepart	; draw the head

		load.w r0,#9
		callbranch breakpoint

		load.w r1,movementdelay		; add an appropriate delay
		clear r0			; will delay by a chunk
.delay:		sub r0,#0x100			; 256 iterations
		branchnz .delay			; repeat inner loop
		dec r1				; dec outer movementdelay
		branchnz .delay			; repeat outer loop

		branch mainloop			; back down the mainloop

death:		load.bu r0,lives		; decrementing the lives
		dec r0				; ...
		store.b lives,r0		; ...
		test r0				; see if there's more lives
		branchnz newlife		; yes? start game again

		callbranch drawplayarea		; otherwise redraw
		load.bu r0,#HEIGHT/2		; centre rows
		load.bu r1,#(WIDTH/2)-(9/2)	; center cols
		load.bu r2,#gameovermsg		; game over message
		callbranch printmsg		; print it

.wait:		callbranch getps2byte		; get a scancode
		test r0				; checking for zero
		branchz .wait			; back to waiting
		branch newgame			; play the game game on key

;;;

randominit:	load.w r0,#1			; for now init to 1
		store.w randomseed,r0		; save the seed
		return

randomnumber:	load.w r0,randomseed		; get the current seed
		test r0				; 0?
		branchz doeor			; if yes do the xor
		logicleft r0 			; logic it up
		branchz noeor			; no xor if input 8000
		branchnc noeor			; no 1 in carry? logic
doeor:		xor r0,#0x002d			; magic
noeor:		store.w randomseed,r0		; save the latest number
		return

drawplayarea:	clear r0			; AKA TILE_BLANKx2
		load.w r1,#WIDTH*HEIGHT		; number of rows
.clearloop:	decd r1				; clearing words
		store.w (ORIGIN,r1),r0		; blank it
		test r1				; writing words
		branchnz .clearloop		; more?

		load.bu r0,#TILE_BORDER_TL
		store.b ORIGIN,r0
		load.bu r0,#TILE_BORDER_TR
		store.b ORIGIN+(WIDTH-1),r0
		load.bu r0,#TILE_BORDER_BL
		store.b ORIGIN+(WIDTH*(HEIGHT-1)),r0
		load.bu r0,#TILE_BORDER_BR
		store.b ORIGIN+((WIDTH*HEIGHT)-1),r0

		load.bu r0,#TILE_BORDER_H
		clear r1
		load.w r2,#WIDTH-2
horizloop:	store.b (ORIGIN+1,r1),r0
		store.b (ORIGIN+1+(WIDTH*(HEIGHT-1)),r1),r0
		inc r1
		dec r2
		jumpnz horizloop		; jump for fun

		load.bu r0,#TILE_BORDER_V
		clear r1
		load.w r2,#HEIGHT-2
vertloop:	store.b (ORIGIN+WIDTH,r1),r0
		store.b (ORIGIN+(WIDTH+(WIDTH-1)),r1),r0
		add r1,#WIDTH
		dec r2
		branchnz vertloop

		clear r0			; top row
		load.bu r1,#((WIDTH/4)*1)-(8/2)	; center left half
		load.w r2,#titlemsg		; the tile
		callbranch printmsg

		load.bu r0,(lives,pc)		; get current lives
		add r0,#0x30			; ascii 0
		store.b (livesmsg+7),r0		; add the number
		clear r0			; top row
		load.bu r1,#((WIDTH/4)*3)-(9/2)	; center right half
		load.w r2,#livesmsg		; get lives: string
		callbranch printmsg		; print it

		return

placenewfood:	callbranch randomnumber		; get latest prng
		and r0,#15			; highest power of 2
		add r0,#(30-16)/2		; center it
		copy r1,r0			; row
		callbranch randomnumber		; get another
		and r0,#31			; highest power of 2
		add r0,#(40-32)/2		; center it
		mulu r1,#WIDTH			; get the line start
		add r1,r0			; add coloumn count
		load.bu r0,(ORIGIN,r1)		; get the current
		test r0				; looking for empty
		branchnz placenewfood		; try again?
		load.bu r0,#TILE_HEART		; food
		store.b (ORIGIN,r1),r0		; place it
		return

; draws the tile at r0 for the given snake position at r1

drawsnakepart:	load.bu r2,(rowsnake,r1)	; get the row no
		mulu r2,#WIDTH			; get the line start
		load.bu r1,(colsnake,r1)	; get the col no
		add r2,r1			; add the col no to start
		store.b (ORIGIN,r2),r0		; update the screen
		return

steersnake:	callbranch getps2byte
		compare r0,#KEY_A
		branchz left
		compare r0,#KEY_D
		branchz right
		compare r0,#KEY_W
		branchz up
		compare r0,#KEY_S
		branchz down
steersnakeo:	return

right:		load.bu r0,snakedirection
		compare r0,#2
		branchz steersnakeo
		load.bu r0,#1
		store.b coldirection,r0
		clear r0
		store.b rowdirection,r0
		clear r0
		store.b snakedirection,r0
		return
up:		load.bu r0,snakedirection
		compare r0,#3
		branchz steersnakeo
		clear r0
		store.b coldirection,r0
		load.bu r0,#-1
		store.b rowdirection,r0
		load.bu r0,#1
		store.b snakedirection,r0
		return
left:		load.bu r0,snakedirection
		test r0
		branchz steersnakeo
		load.bu r0,#-1
		store.b coldirection,r0
		clear r0
		store.b rowdirection,r0
		load.bu r0,#2
		store.b snakedirection,r0
		return
down:		load.bu r0,snakedirection
		compare r0,#1
		branchz steersnakeo
		clear r0
		store.b coldirection,r0
		load.bu r0,#1
		store.b rowdirection,r0
		load.bu r0,#3
		store.b snakedirection,r0
		return

movesnake:	load.bu r0,headpos		; get head index

		load.bu r2,(rowsnake,r0)	; get the current head pos
		load.bs r1,rowdirection		; get the direction
		add r2,r1			; moving that way
		inc r0				; move to next slot
		and r0,#0xff			; wrap it
		store.b (rowsnake,r0),r2	; save that row number

		load.bu r0,headpos		; get head index again

		load.bu r2,(colsnake,r0)	; get the current head pos
		load.bs r1,coldirection		; get the direction
		add r2,r1			; moving that way
		inc r0				; move to next slot
		and r0,#0xff			; wrap it
		store.b (colsnake,r0),r2	; save that row number

		load.bu r0,headpos		; move the head
		inc r0				; move to the next slot
		and r0,#0xff			; wrap it
		store.b headpos,r0		; save it back

		return

docollision:	load.bu r1,headpos
		load.bu r2,(rowsnake,r1)	; get the row no
		mulu r2,#WIDTH			; get the line start
		load.bu r1,(colsnake,r1)	; get the col no
		add r2,r1			; add the col no to start
		load.bu r0,(ORIGIN,r2)		; get whats there now
		test r0				; checking whats there?
		branchz emptysquare		; vacant square
		compare r0,#TILE_HEART		; compare with food
		branchz yumyum			; yes? eat it!
		load.w r0,#1			; mark death for caller
		return
yumyum:		load.bu r0,snakelength		; get length
		inc r0				; snake gets longer
		store.b snakelength,r0		; save new length
		load.w r0,movementdelay		; get current delay
		sub r0,#5			; decrease it a bit
		store.w movementdelay,r0	; save it back out
		callbranch placenewfood		; more food!
emptysquare:	clear r0			; not death
		return

; prints the msg at r2 at row r0 coloumn r1

printmsg:	mulu r0,#WIDTH			; get the start of the row
		add r0,r1			; add the column
.loop:		load.bu r1,(r2)			; get the char
		test r1				; checking for null
		branchz printmsgo		; done?
		store.b (ORIGIN,r0),r1		; output the char
		inc r2				; move to next char
		inc r0
		branch .loop
printmsgo:	return

; gets a byte from ps2 port in r0, but does not wait for it, r0=0 means
; nothing currently available

getps2byte:	load.bu r0,PS2_STATUS		; get from the status reg
		test r0				; nothing?
		branchz .nothing		; keep waiting....
		load.bu r0,PS2_SCANCODE		; get the scancode
		compare r0,#0xf0		; key-break seqence
		branchz .nothing		; yes? exit early
		store.w SEVENSEG,r0		; output the scancode (fun)
		return				; done
.nothing:	clear r0			; nothing? set 0 in r0
		return

; write the string in r0 to the lcd address r1, which might be control or
; data

lcdoutput:	load.bu r2,(r0)			; get the char
		test r2				; checking for null
		branchz lcdmsgo			; done?
		load.w r3,LCD_BUSY		; read the busy address
		test r3				; busy?
		branchnz lcdoutput		; yes, back to waiting
		store.b (r1),r2			; output the char
		inc r0				; next char to read
		branch lcdoutput		; and continue
lcdmsgo:	return

;;; debugging

breakpoint:	;store.w SEVENSEG,r0
.l1:		;load.w r0,BUTTONS
		;and r0,#1
		;store.w SEVENSEG,r0
		;branchnz .l1
.l2:		;load.w r0,BUTTONS
		;store.w SEVENSEG,r0
		;bit r0,#1
		;branchz .l2
		return

titlemsg:	#str " Snake! \0"
livesmsg:	#str " Lives:X \0"
gameovermsg:	#str "Game Over\0"
lcdtitlemsg:	#str "X   Snake v0.1   XXXXXXXXXXXXXXXXXXXXXXXX"
		#str "Lawrence ManningXXXXXXXXXXXXXXXXXXXXXXXX\0"

lcdinitseq:	#d8 0x30
		#d8 0x30
		#d8 0x30
		#d8 0x0c
		#d8 0x38
		#d8 0x01
		#d8 0

#align 2

bss:

; variables: words

movementdelay:	#res 2			; 600*256 decreasing 5*256 per food
randomseed:	#res 2

; variables: bytes

lives:		#res 1
snakelength:	#res 1
headpos:	#res 1

rowdirection:	#res 1
coldirection:	#res 1
snakedirection:	#res 1

; positions

rowsnake:	#res 256
colsnake:	#res 256
