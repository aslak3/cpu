library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clockdiv is
	port (
		CLOCKIN : in STD_LOGIC;
		RESET : in STD_LOGIC;
		CLOCKOUT : out STD_LOGIC
	);
end entity;

architecture behavioral of clockdiv is
	signal COUNTER : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
begin
	process (RESET, CLOCKIN)
	begin
		if (RESET = '1') then
			COUNTER <= (others => '0');
		elsif (CLOCKIN'Event and CLOCKIN = '1') then
			COUNTER <= COUNTER + 1;
		end if;
	end process;

	CLOCKOUT <= COUNTER(5);
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.P_CONTROL.all;
use work.P_TB_CPU.all;
use work.P_RAM.all;

entity cpu_tb is
end entity;

architecture behavioral of cpu_tb is
	signal CLOCK50M : STD_LOGIC;
	signal CLOCK : STD_LOGIC;
	signal CLOCK_MAIN : STD_LOGIC;
	signal CLOCK_DELAYED : STD_LOGIC;
	signal RESET : STD_LOGIC := '0';

	signal ADDRESS : STD_LOGIC_VECTOR (14 downto 0);
	signal DATA_IN : STD_LOGIC_VECTOR (15 downto 0);
	signal DATA_OUT : STD_LOGIC_VECTOR (15 downto 0);
	signal UPPER_DATA : STD_LOGIC;
	signal LOWER_DATA : STD_LOGIC;
	signal BUS_ERROR : STD_LOGIC;
	signal READ : STD_LOGIC;
	signal WRITE : STD_LOGIC;

begin
	process
	begin
		CLOCK50M <= '0';
		wait for 1 ns;
		CLOCK50M <= '1';
		wait for 1 ns;
	end process;

	clockdiv: entity work.clockdiv port map (
		CLOCKIN => CLOCK50M,
		RESET => RESET,
		CLOCKOUT => CLOCK
	);

	dut: entity work.cpu port map (
		CLOCK => CLOCK,
		CLOCK_MAIN => CLOCK_MAIN,
		CLOCK_DELAYED => CLOCK_DELAYED,
		RESET => RESET,
		ADDRESS => ADDRESS,
		DATA_IN => DATA_IN,
		DATA_OUT => DATA_OUT,
		UPPER_DATA => UPPER_DATA,
		LOWER_DATA => LOWER_DATA,
		BUS_ERROR => BUS_ERROR,
		READ => READ,
		WRITE => WRITE
	);

	process (CLOCK_DELAYED)
	begin
		if (CLOCK_DELAYED'Event and CLOCK_DELAYED = '1') then
			report "Address=" & to_hstring(ADDRESS & '0') &
				" Read=" & STD_LOGIC'image(READ) & " Write=" & STD_LOGIC'image(WRITE) &
				" Data Out=" & to_hstring(DATA_OUT) & " Data In=" & to_hstring(DATA_IN) &
				" Upper=" & STD_LOGIC'image(UPPER_DATA) & " Lower=" & STD_LOGIC'image(LOWER_DATA);

			if (WRITE = '1') then
				if (ADDRESS (14 downto 12) = "000") then
					if (UPPER_DATA = '1') then
						report "Writing upper to " & to_hstring(ADDRESS & '0');
						RAM(to_integer(unsigned(ADDRESS))) (15 downto 8) <= DATA_OUT (15 downto 8);
					end if;
					if (LOWER_DATA = '1') then
						report "Writing lower to " & to_hstring(ADDRESS & '1');
						RAM(to_integer(unsigned(ADDRESS))) (7 downto 0) <= DATA_OUT (7 downto 0);
					end if;
				elsif (ADDRESS (14 downto 7) = "01000000") then
					report "Setting LED to " & STD_LOGIC'Image(DATA_OUT (0));
				elsif (ADDRESS (14 downto 7) = "01000001") then
					report "Setting 7 Segment to " & to_hstring(DATA_OUT);
				elsif (ADDRESS (14 downto 7) = "01000010") then
					report "Setting Buzzer " & to_hstring(DATA_OUT);
				elsif (ADDRESS (14) = '1') then
					report "Writing to video memory " & to_hstring(DATA_OUT) & " @ " & to_hstring(ADDRESS & '0');
				end if;
			end if;

			if (READ = '1') then
				if (ADDRESS (14 downto 13) = "00") then
					report "Reading from " & to_hstring(ADDRESS & '0');
					DATA_IN <= RAM(to_integer(unsigned(ADDRESS)));
				elsif (ADDRESS (14 downto 7) = "01000100") then
					report "Reading from button";
					DATA_IN <= x"0000";
				end if;
			end if;
		end if;
	end process;

	process
		procedure clock_delay is
		begin
			wait until (CLOCK_DELAYED = '0');
			wait until (CLOCK_DELAYED = '1');
		end procedure;

		variable MY_LINE : LINE;  -- type 'line' comes from textio
	begin

		RESET <= '1';
		wait for 1 us;
		RESET <= '0';

		for C in 0 to 8000 loop
			clock_delay;
			if  (BUS_ERROR = '1') then
				report "Bus error at " & to_hstring(ADDRESS) & " HALTED";
				exit;
			end if;
		end loop;

		std.textio.write(std.textio.output, "Memory dump (0 to 255)" & LF);

		for C in 0 to 255 loop
			std.textio.write(std.textio.output, INTEGER'image(C) & " = " & to_hstring(RAM(C)) & " (" & INTEGER'image(to_integer(unsigned(RAM(C)))) & ")" & LF);
		end loop;

		std.env.finish;
	end process;
end architecture;
