start:		load.w r0,#0x1234
		load.w r1,#0x0200
		store.w (r1),r0
hop:		jump hop
