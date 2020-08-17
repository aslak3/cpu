library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_CPU.all;

entity cpu_tb is
end entity;

architecture behavioral of cpu_tb is
	signal CLOCK : STD_LOGIC;
	signal RESET : STD_LOGIC;
	signal CPU_ADDRESS : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_IN : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_OUT : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_READ : STD_LOGIC;
	signal CPU_WRITE : STD_LOGIC;
	type MEM is ARRAY (0 to 31) of T_OPCODE;
	signal RAM : MEM := (
		x"0011",  -- 00: LOADI #0x0a,r1
		x"0010",  -- 01:
		x"0010",  -- 02: LOADI #0x03,r0
		x"00ff",  -- 03: n
		x"0088",  -- 04: STORER r0,(r1)
		x"1401",  -- 05: INC r1
		x"1d00",  -- 06: DEC r0
		x"000c",  -- 07: JUMPNZ 4
		x"0004",  -- 08: n
		x"0009",  -- 09: NOP
		x"0009",  -- 0a: NOP
		x"0000",  -- 0b: NOP
		x"0000",  -- 0c: NOP
		x"0000",  -- 0d: NOP
		x"0000",  -- 0e: NOP
		x"0000",  -- 0f: NOP
		x"0000",  -- 10: NOP
		x"0000",  -- 11: NOP
		x"0000",  -- 12: NOP
		x"0000",  -- 13: NOP
		x"0000",  -- 14: NOP
		x"0000",  -- 15: NOP
		x"0000",  -- 16: NOP
		x"0000",  -- 17: NOP
		x"0000",  -- 18: NOP
		x"0000",  -- 19: NOP
		x"0000",  -- 1a: NOP
		x"0000",  -- 1b: NOP
		x"0000",  -- 1c: NOP
		x"0000",  -- 1d: NOP
		x"0000",  -- 1e: NOP
		x"0000"   -- 1f: NOP
	);
	
begin
	dut: entity work.cpu port map (
		CLOCK => CLOCK,
		RESET => RESET,
		ADDRESS => CPU_ADDRESS,
		DATA_IN => CPU_DATA_IN,
		DATA_OUT => CPU_DATA_OUT,
		READ => CPU_READ,
		WRITE => CPU_WRITE
	);

	process (CPU_WRITE, CPU_ADDRESS)
	begin
		if (CPU_WRITE = '1') then
			RAM(to_integer(unsigned(CPU_ADDRESS))) <= CPU_DATA_OUT;
		end if;
		CPU_DATA_IN <= RAM(to_integer(unsigned(CPU_ADDRESS)));
	end process;
	
	process
		procedure clock_delay is
		begin
			CLOCK <= '0';
			wait for 1 ns;
			CLOCK <= '1';
			wait for 1 ns;
		end procedure;
	begin
		
		RESET <= '1';
		wait for 1 ns;
		RESET <= '0';
		wait for 1 ns;
	
		for C in 0 to 500 loop
			report "Addres=" & to_hstring(CPU_ADDRESS) &
				" Read=" & STD_LOGIC'image(CPU_READ) & " WRITE=" & STD_LOGIC'image(CPU_WRITE) &
				" Data Out=" & to_hstring(CPU_DATA_OUT) & " Data In=" & to_hstring(CPU_DATA_IN);		
			clock_delay;
		end loop;

		report "Memory dump";
		
		for C in 0 to 31 loop
			report integer'image(C) & " = " & to_hstring(RAM(C));
		end loop;
		
		report "+++All good";
		std.env.finish;
	end process;
end architecture;
