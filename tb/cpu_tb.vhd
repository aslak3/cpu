library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use work.P_CONTROL.all;

entity cpu_tb is
end entity;

architecture behavioral of cpu_tb is
	signal CLOCK50M : STD_LOGIC;
	signal CLOCK : STD_LOGIC;
	signal CLOCK_MAIN : STD_LOGIC;
	signal RESET : STD_LOGIC := '0';

	signal ADDRESS : STD_LOGIC_VECTOR (14 downto 0);
	signal DATA_IN : STD_LOGIC_VECTOR (15 downto 0);
	signal DATA_OUT : STD_LOGIC_VECTOR (15 downto 0);
	signal UPPER_DATA : STD_LOGIC;
	signal LOWER_DATA : STD_LOGIC;
	signal BUS_ERROR : STD_LOGIC;
	signal HALTED : STD_LOGIC;
	signal READ : STD_LOGIC;
	signal WRITE : STD_LOGIC;

	signal RAM_DATA_in : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal RAM_DATA_OUT : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal RAM_WRITE : STD_LOGIC;

	signal LEDR : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal SEVENSEG_DATA : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal VGA_DATA_IN : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
begin
	process
	begin
		CLOCK50M <= '0';
		wait for 1 ns;
		CLOCK50M <= '1';
		wait for 1 ns;
	end process;

	intram: entity work.intram port map (
		address => ADDRESS (11 downto 0),
		byteena => UPPER_DATA & LOWER_DATA,
		clock => CLOCK50M,
		data => RAM_DATA_IN,
		wren => RAM_WRITE,
		q => RAM_DATA_OUT
	);

	dut: entity work.cpu port map (
		CLOCK => CLOCK50M,
		CLOCK_MAIN => CLOCK_MAIN,
		RESET => RESET,
		ADDRESS => ADDRESS,
		DATA_IN => DATA_IN,
		DATA_OUT => DATA_OUT,
		UPPER_DATA => UPPER_DATA,
		LOWER_DATA => LOWER_DATA,
		BUS_ERROR => BUS_ERROR,
		READ => READ,
		WRITE => WRITE,
		HALTED => HALTED
	);

	RAM_DATA_IN <= DATA_OUT when (WRITE = '1' and ADDRESS (14 downto 12) = "000") else x"0000";
	RAM_WRITE <= '1' when (WRITE = '1' and ADDRESS (14 downto 12) = "000") else '0';
	LEDR <= DATA_OUT when (WRITE = '1' and ADDRESS (14 downto 7) = x"80");
	SEVENSEG_DATA <= DATA_OUT when (WRITE = '1' and ADDRESS (14 downto 7) = x"81");
	VGA_DATA_IN <= DATA_OUT when (WRITE = '1' and ADDRESS (14) = '1');

	DATA_IN <= RAM_DATA_OUT when (READ = '1' and ADDRESS (14 downto 12) = "000") else x"0000";

	process (LEDR)
	begin
		report "LED now at " & to_hstring(LEDR);
	end process;

	process (SEVENSEG_DATA)
	begin
		report "7 segment now at " & to_hstring(SEVENSEG_DATA);
	end process;

	process (VGA_DATA_IN)
	begin
		report "VGA write " & to_hstring(ADDRESS) & "=" & to_hstring(VGA_DATA_IN);
	end process;

	process (READ, WRITE)
	begin
		report "ADDRESS=" & to_hstring(ADDRESS & '0') & " READ=" & STD_LOGIC'Image(READ) &
		" WRITE=" & STD_LOGIC'Image(WRITE) & " DATA_IN=" & to_hstring(DATA_IN) &
		" DATA_OUT=" & to_hstring(DATA_OUT);
	end process;

	process
		procedure clock_delay is
		begin
			wait until (CLOCK_MAIN = '0');
			wait until (CLOCK_MAIN = '1');
		end procedure;

		variable MY_LINE : LINE;  -- type 'line' comes from textio
	begin

		RESET <= '1';
		wait for 1 us;
		RESET <= '0';

		for C in 0 to 8000 loop
			clock_delay;
			if (BUS_ERROR = '1') then
				report "Bus error at " & to_hstring(ADDRESS & '0') & " HALTED";
				exit;
			end if;
			if (HALTED = '1') then
				report "Processor HALT at " & to_hstring(ADDRESS & '0');
				exit;
			end if;
		end loop;

		std.env.finish;
	end process;
end architecture;
