start:	jump start
	load.w r7,#0x1234
	load.bu r0,(r7)
	load.bs r1,(0x1234,r2)
	store.b 0x1234,r0
	store.w (r0),r7
	store.b (0x4321,r0),r0
foo:	branchnz foo
	clear r7
	add r1,r2
	xori r7,#0x1234
	calljump foo
	callbranch start
	return
	pushquick (r7),r0
	popquick r0,(r7)
	pushmulti (r7),R2|R0|R5
	popmulti R7|R2,(r7)
