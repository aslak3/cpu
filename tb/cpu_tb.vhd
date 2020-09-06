library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Types for the registers presented

package P_TB_CPU is
	type T_SELECTNAMES is (
		SELECT_RAM,
		SELECT_LED,
		SELECT_SEVENSEG,
		SELECT_VGA_CONTROL,
		SELECT_BUZZER,
		SELECT_VGA_MEMORY
	);
	type T_SELECT_LOGIC is array (T_SELECTNAMES) of STD_LOGIC;
end package;

---

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
use work.P_TB_CPU.all;

entity addressdecoder is
	port (
		CLOCK : in STD_LOGIC;
		ADDRESS : in STD_LOGIC_VECTOR (7 downto 0);
		SELECTS : out T_SELECT_LOGIC
	);
end entity;

architecture behaviorual of addressdecoder is
begin
	process (CLOCK)
	begin
		if (CLOCK'Event and CLOCK = '1') then
			SELECTS <= (others => '0');
			case? ADDRESS is
				when x"00" =>
					SELECTS(SELECT_RAM) <= '1';
				when x"01" =>
					SELECTS(SELECT_LED) <= '1';
				when x"02" =>
					SELECTS(SELECT_SEVENSEG) <= '1';
				when x"03" =>
					SELECTS(SELECT_VGA_CONTROL) <= '1';
				when x"04" =>
					SELECTS(SELECT_BUZZER) <= '1';
				when "1-------" =>
					SELECTS(SELECT_VGA_MEMORY) <= '1';
				when others =>
			end case?;
		end if;
	end process;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.P_CONTROL.all;
use work.P_TB_CPU.all;

entity cpu_tb is
end entity;

architecture behavioral of cpu_tb is
	signal CLOCK50M : STD_LOGIC;
	signal CLOCK : STD_LOGIC;
	signal RESET : STD_LOGIC := '0';
	
	signal AD_SELECTS : T_SELECT_LOGIC;
	
	signal CPU_ADDRESS : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_IN : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_OUT : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_READ : STD_LOGIC;
	signal CPU_WRITE : STD_LOGIC;

	type MEM is ARRAY (0 to 63) of STD_LOGIC_VECTOR (15 downto 0);
	signal RAM : MEM := (
x"2000",
x"f00f",
x"2001",
x"8000",
x"2007",
x"0040",
x"403f",
x"000f",
x"2002",
x"0002",
x"3942",
x"0c90",
x"fffe",
x"0800",
x"0006",
x"2002",
x"001a",
x"2813",
x"3902",
x"2c0b",
x"3901",
x"3fc3",
x"0000",
x"0890",
x"0011",
x"483f",
x"4800",
x"6500",
x"6c00",
x"6c00",
x"6f00",
x"2000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000"

);

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

	addressdecoder: entity work.addressdecoder port map (
		CLOCK => CLOCK50M,
		ADDRESS => CPU_ADDRESS (15 downto 8),
		SELECTS => AD_SELECTS
	);

	dut: entity work.cpu port map (
		CLOCK => CLOCK,
		RESET => RESET,
		ADDRESS => CPU_ADDRESS,
		DATA_IN => CPU_DATA_IN,
		DATA_OUT => CPU_DATA_OUT,
		READ => CPU_READ,
		WRITE => CPU_WRITE
	);

	CPU_DATA_IN <= RAM(to_integer(unsigned(CPU_ADDRESS))) when (AD_SELECTS(SELECT_RAM) = '1' and CPU_READ = '1') else
		(others => 'X');
	
	process (CLOCK50M)
	begin
		if (CLOCK50M'Event and CLOCK50M = '1') then
			if (CPU_WRITE = '1') then
				if (AD_SELECTS(SELECT_RAM) = '1') then
					RAM(to_integer(unsigned(CPU_ADDRESS))) <= CPU_DATA_OUT;
				elsif (AD_SELECTS(SELECT_LED) = '1') then
					report "Setting LED to " & STD_LOGIC'Image(CPU_DATA_OUT (0));
				elsif (AD_SELECTS(SELECT_SEVENSEG) = '1') then
					report "Setting 7 Segment to " & to_hstring(CPU_DATA_OUT);
				elsif (AD_SELECTS(SELECT_BUZZER) = '1') then
					report "Setting Buzzer " & to_hstring(CPU_DATA_OUT);
				elsif (AD_SELECTS(SELECT_VGA_MEMORY) = '1') then
					report "Writing to video memory " & to_hstring(CPU_DATA_OUT) & " @ " & to_hstring(CPU_ADDRESS);
				end if;
			end if;
		end if;
	end process;

	process
		procedure clock_delay is
		begin
			wait until (CLOCK = '0');
			wait until (CLOCK = '1');
		end procedure;

		variable MY_LINE : LINE;  -- type 'line' comes from textio
	begin

		RESET <= '1';
		wait for 1 us;
		RESET <= '0';

		for C in 0 to 1000 loop
			report "Address=" & to_hstring(CPU_ADDRESS) &
				" Read=" & STD_LOGIC'image(CPU_READ) & " Write=" & STD_LOGIC'image(CPU_WRITE) &
				" Data Out=" & to_hstring(CPU_DATA_OUT) & " Data In=" & to_hstring(CPU_DATA_IN);
			clock_delay;
		end loop;

		write(MY_LINE, string'("Memory dump"));
		writeline(OUTPUT, MY_LINE);

		for C in 0 to 63 loop
			write(MY_LINE, INTEGER'image(C) & " = " & to_hstring(RAM(C)) & " (" & INTEGER'image(to_integer(unsigned(RAM(C)))) & ")");
			writeline(OUTPUT, MY_LINE);
		end loop;

		std.env.finish;
	end process;
end architecture;
