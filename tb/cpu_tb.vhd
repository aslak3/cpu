library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.P_CONTROL.all;

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
	type MEM is ARRAY (0 to 31) of STD_LOGIC_VECTOR (15 downto 0);
	signal RAM : MEM := (
x"3000",
x"2001",
x"0001",
x"2003",
x"0000",
x"2004",
x"0008",
x"280F",
x"3B0A",
x"3801",
x"3B10",
x"6C19",
x"0018",
x"3C03",
x"0001",
x"3944",
x"1C90",
x"FFF7",
x"2000",
x"2A2A",
x"2400",
x"001F",
x"1800",
x"FFFF",
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

	process (CPU_WRITE, CPU_READ, CPU_ADDRESS)
	begin
		if (CPU_WRITE = '1') then
			RAM(to_integer(unsigned(CPU_ADDRESS))) <= CPU_DATA_OUT;
		end if;
		if (CPU_READ = '1') then
			CPU_DATA_IN <= RAM(to_integer(unsigned(CPU_ADDRESS)));
		end if;
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
