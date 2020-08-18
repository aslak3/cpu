library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;
use IEEE.std_logic_textio.all;
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
x"0030",
x"0011",
x"0001",
x"0013",
x"0011",
x"0014",
x"000F",
x"1E0A",
x"1001",
x"1E10",
x"0099",
x"1403",
x"1604",
x"000C",
x"0007",
x"0008",
x"000F",
		x"0000",  -- 14: NOP
		x"0000",  -- 14: NOP
		x"0000",  -- 14: NOP
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
		variable MY_LINE : LINE;  -- type 'line' comes from textio
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

		write(MY_LINE, string'("Memory dump"));
		writeline(OUTPUT, MY_LINE);

		for C in 0 to 31 loop
			write(MY_LINE, INTEGER'image(C) & " = " & to_hstring(RAM(C)) & " (" & INTEGER'image(to_integer(unsigned(RAM(C)))) & ")");
			writeline(OUTPUT, MY_LINE);
		end loop;

		report "+++All good";
		std.env.finish;
	end process;
end architecture;
