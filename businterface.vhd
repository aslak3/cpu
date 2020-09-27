library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity businterface is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;

		CPU_ADDRESS : in STD_LOGIC_VECTOR (15 downto 0);
		CPU_BUS_ACTIVE : in STD_LOGIC;
		CPU_CYCLETYPE_BYTE : in STD_LOGIC;
		CPU_DATA_OUT : in STD_LOGIC_VECTOR (15 downto 0);
		CPU_DATA_IN : out STD_LOGIC_VECTOR (15 downto 0);
		CPU_READ : in STD_LOGIC;
		CPU_WRITE : in STD_LOGIC;

		BUSINTERFACE_ADDRESS : out STD_LOGIC_VECTOR (14 downto 0);
		BUSINTERFACE_DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		BUSINTERFACE_DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		BUSINTERFACE_UPPER_DATA : out STD_LOGIC;
		BUSINTERFACE_LOWER_DATA : out STD_LOGIC;
		BUSINTERFACE_ERROR : out STD_LOGIC;
		BUSINTERFACE_READ : out STD_LOGIC;
		BUSINTERFACE_WRITE : out STD_LOGIC
	);
end entity;

architecture behavioral of businterface is
begin
	process (CLOCK)
	begin
		if (CLOCK'Event and CLOCK = '1') then
			BUSINTERFACE_UPPER_DATA <= '0';
			BUSINTERFACE_LOWER_DATA <= '0';
			BUSINTERFACE_ERROR <= '0';

			-- Shift the addres to being a word address, moving low bit to upper/lower indicators
			BUSINTERFACE_ADDRESS <= CPU_ADDRESS (15 downto 1);
			if (CPU_CYCLETYPE_BYTE = '0' or CPU_ADDRESS (0) = '0') then
				BUSINTERFACE_UPPER_DATA <= '1';
			end if;
			if (CPU_CYCLETYPE_BYTE = '0' or CPU_ADDRESS (0) = '1') then
				BUSINTERFACE_LOWER_DATA <= '1';
			end if;
			if (CPU_CYCLETYPE_BYTE = '0' and CPU_ADDRESS (0) = '1' and CPU_BUS_ACTIVE = '1') then
				BUSINTERFACE_ERROR <= '1';
			end if;

			if (CPU_CYCLETYPE_BYTE = '0' and CPU_ADDRESS (0) = '0') then
				BUSINTERFACE_DATA_OUT <= CPU_DATA_OUT;
				CPU_DATA_IN <= BUSINTERFACE_DATA_IN;
			elsif (CPU_ADDRESS (0) = '0') then
				BUSINTERFACE_DATA_OUT <= CPU_DATA_OUT (7 downto 0) & x"ff";
				CPU_DATA_IN <= x"ff" & BUSINTERFACE_DATA_IN (15 downto 8);
			elsif (CPU_ADDRESS (0) = '1') then
				BUSINTERFACE_DATA_OUT <= x"ff" & CPU_DATA_OUT (7 downto 0);
				CPU_DATA_IN <= x"ff" & BUSINTERFACE_DATA_IN (7 downto 0);
			else
				BUSINTERFACE_DATA_OUT <= x"ffff";
				CPU_DATA_IN <= x"ffff";
			end if;

			BUSINTERFACE_READ <= CPU_READ;
			BUSINTERFACE_WRITE <= CPU_WRITE;

		end if;
	end process;
end architecture;
