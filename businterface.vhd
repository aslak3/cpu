library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity businterface is
	port (
		CPU_ADDRESS : in STD_LOGIC_VECTOR (15 downto 0);
		CPU_CYCLE_TYPE_BYTE : in STD_LOGIC;
		CPU_DATA_OUT : in STD_LOGIC_VECTOR (15 downto 0);
		CPU_DATA_IN : out STD_LOGIC_VECTOR (15 downto 0);

		BUSINTERFACE_ADDRESS : out STD_LOGIC_VECTOR (14 downto 0);
		BUSINTERFACE_DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		BUSINTERFACE_DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		BUSINTERFACE_UPPER_DATA : out STD_LOGIC;
		BUSINTERFACE_LOWER_DATA : out STD_LOGIC;
		BUSINTERFACE_ERROR : out STD_LOGIC;

		READ : in STD_LOGIC;
		WRITE : in STD_LOGIC
	);
end entity;

architecture behavioral of businterface is
begin
	-- Shift the addres to being a word address, moving low bit to upper/lower indicators
	BUSINTERFACE_ADDRESS <= CPU_ADDRESS (15 downto 1);
	BUSINTERFACE_UPPER_DATA <= '1' when (CPU_CYCLE_TYPE_BYTE = '0' or CPU_ADDRESS (0) = '0') else '0';
	BUSINTERFACE_LOWER_DATA <= '1' when (CPU_CYCLE_TYPE_BYTE = '0' or CPU_ADDRESS (0) = '1') else '0';
	-- Signal an error on unaligned word accesses
	BUSINTERFACE_ERROR <= '1' when (CPU_CYCLE_TYPE_BYTE = '0' and CPU_ADDRESS (0) = '1' and (
		READ = '1' or WRITE = '1')
	) else '0';

	-- CPU writes
	BUSINTERFACE_DATA_OUT <=
		CPU_DATA_OUT when (CPU_CYCLE_TYPE_BYTE = '0' and CPU_ADDRESS (0) = '0') else
		-- Data needs to be moved from low half to either high or low half, based on low address bit
		-- Unused portions should be ignored, force them to a noteable value
		CPU_DATA_OUT (7 downto 0) & x"ff" when (CPU_ADDRESS (0) = '0') else
		x"ff" & CPU_DATA_OUT (7 downto 0) when (CPU_ADDRESS (0) = '1') else
		x"ffff";

	-- CPU reads
	CPU_DATA_IN <=
		BUSINTERFACE_DATA_IN when (CPU_CYCLE_TYPE_BYTE = '0') else
		-- Data needs to be in the low half, selected by address low bit
		-- Unused portions should be ignored, force them to a noteable value
		x"ff" & BUSINTERFACE_DATA_IN (15 downto 8) when (CPU_ADDRESS (0) = '0') else
		x"ff" & BUSINTERFACE_DATA_IN (7 downto 0) when (CPU_ADDRESS (0) = '1') else
		x"ffff";
end architecture;
