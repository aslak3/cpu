library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity businterface is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		ADDRESS : out STD_LOGIC_VECTOR (15 downto 1);
		DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		UPPER_DATA : out STD_LOGIC;
		LOWER_DATA : out STD_LOGIC;
		READ : out STD_LOGIC;
		WRITE : out STD_LOGIC
	);
end entity;

architecture behavioral of businterface is
	signal CPU_ADDRESS : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_IN : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_DATA_OUT : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_CYCLE_TYPE_BYTE : STD_LOGIC;
begin
	process (CLOCK)
	begin
		if (CLOCK'Event and CLOCK = '1') then
			report "Bus Interface from CPU:" &
				" ADDRESS=" & to_hstring(CPU_ADDRESS) &
				" CYCLE_TYPE_BYTE=" & STD_LOGIC'Image(CPU_CYCLE_TYPE_BYTE) &
				" DATA_IN=" & to_hstring(CPU_DATA_IN) &
				" DATA_OUT=" & to_hstring(CPU_DATA_OUT) &
				" READ=" & STD_LOGIC'Image(READ) &
				" WRITE=" & STD_LOGIC'Image(WRITE);
		end if;
	end process;

	cpu: entity work.cpu port map (
		CLOCK => CLOCK,
		RESET => RESET,
		ADDRESS => CPU_ADDRESS,
		CYCLE_TYPE_BYTE => CPU_CYCLE_TYPE_BYTE,
		DATA_IN => CPU_DATA_IN,
		DATA_OUT => CPU_DATA_OUT,
		READ => READ,
		WRITE => WRITE
	);

	-- Shift the addres to being a word address, moving low bit to upper/lower indicators
	ADDRESS <= CPU_ADDRESS (15 downto 1);
	UPPER_DATA <= '1' when (CPU_CYCLE_TYPE_BYTE = '0' or CPU_ADDRESS (0) = '0') else '0';
	LOWER_DATA <= '1' when (CPU_CYCLE_TYPE_BYTE = '0' or CPU_ADDRESS (0) = '1') else '0';

	-- CPU writes
	DATA_OUT <=
		CPU_DATA_OUT when (CPU_CYCLE_TYPE_BYTE = '0') else
		-- Data needs to be moved from low half to either high or low half, based on low address bit
		-- Unused portions should be ignored, force them to a noteable value
		CPU_DATA_OUT (7 downto 0) & x"ff" when (CPU_ADDRESS (0) = '0') else
		x"ff" & CPU_DATA_OUT (7 downto 0) when (CPU_ADDRESS (0) = '1') else
		x"ffff";

	-- CPU reads
	CPU_DATA_IN <=
		DATA_IN when (CPU_CYCLE_TYPE_BYTE = '0') else
		-- Data needs to be in the low half, selected by address low bit
		-- Unused portions should be ignored, force them to a noteable value
		x"ff" & DATA_IN (15 downto 8) when (CPU_ADDRESS (0) = '0') else
		x"ff" & DATA_IN (7 downto 0) when (CPU_ADDRESS (0) = '1') else
		x"ffff";
end architecture;

