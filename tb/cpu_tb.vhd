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
	type MEM is ARRAY (0 to 63) of STD_LOGIC_VECTOR (15 downto 0);
	signal RAM : MEM := (
x"2000",
x"F00F",
x"2007",
x"0040",
x"443F",
x"0003",
x"0C00",
x"FFFF",
x"403F",
x"000B",
x"483F",
x"3005",
x"2001",
x"002A",
x"6809",
x"0001",
x"2003",
x"0000",
x"2004",
x"002C",
x"2824",
x"3B0A",
x"3829",
x"0D24",
x"0009",
x"3B15",
x"6C19",
x"002D",
x"3C03",
x"0001",
x"3944",
x"0C90",
x"FFF5",
x"2005",
x"2A2A",
x"2405",
x"003B",
x"2005",
x"AA55",
x"2001",
x"003A",
x"2C0D",
x"483F",
x"0001",
x"000D",

		x"0000", -- NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000",  --NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000",  --NOP
		x"0000",  --NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000",  --NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000", -- NOP
		x"0000",  --NOP
		x"0000"  -- NOP
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

		for C in 0 to 1000 loop
			report "Addres=" & to_hstring(CPU_ADDRESS) &
				" Read=" & STD_LOGIC'image(CPU_READ) & " WRITE=" & STD_LOGIC'image(CPU_WRITE) &
				" Data Out=" & to_hstring(CPU_DATA_OUT) & " Data In=" & to_hstring(CPU_DATA_IN);
			clock_delay;
		end loop;

		write(MY_LINE, string'("Memory dump"));
		writeline(OUTPUT, MY_LINE);

		for C in 0 to 63 loop
			write(MY_LINE, INTEGER'image(C) & " = " & to_hstring(RAM(C)) & " (" & INTEGER'image(to_integer(unsigned(RAM(C)))) & ")");
			writeline(OUTPUT, MY_LINE);
		end loop;

		report "+++All good";
		std.env.finish;
	end process;
end architecture;
