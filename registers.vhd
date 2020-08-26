 library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_REGS is
	subtype T_REG is STD_LOGIC_VECTOR (15 downto 0);
	type T_REGS is ARRAY (0 to 7) of T_REG;
	subtype T_REG_INDEX is STD_LOGIC_VECTOR (2 downto 0);

	constant DEFAULT_REG : T_REG := x"0000";
	constant DEFAULT_PC : T_REG := x"0000";
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_REGS.all;

entity registers is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		CLEAR : in STD_LOGIC;
		WRITE : in STD_LOGIC;
		READ_LEFT_INDEX : in T_REG_INDEX;
		READ_RIGHT_INDEX : in T_REG_INDEX;
		WRITE_INDEX : in T_REG_INDEX;
		LEFT_OUTPUT : out T_REG;
		RIGHT_OUTPUT : out T_REG;
		INPUT : in T_REG
	);
end entity;

architecture behavioral of registers is
	signal REGISTERS : T_REGS := (others => DEFAULT_REG);
begin
	process (RESET, CLOCK)
	begin
		if (RESET = '1') then
			REGISTERS <= (others => DEFAULT_REG);
		elsif (CLOCK'Event and CLOCK = '1') then
			if (CLEAR = '1') then
--				report "CPU/Registers: Clearing reg " & to_hstring(WRITE_INDEX);
				REGISTERS (to_integer(unsigned(WRITE_INDEX))) <= DEFAULT_REG;
			elsif (WRITE = '1') then
--				report "CPU/Registers: Writing " & to_hstring(INPUT) & " into reg " & to_hstring(WRITE_INDEX);
				REGISTERS (to_integer(unsigned(WRITE_INDEX))) <= INPUT;
			end if;
		end if;
	end process;

	LEFT_OUTPUT <= REGISTERS (to_integer(unsigned(READ_LEFT_INDEX)));
	RIGHT_OUTPUT <= REGISTERS (to_integer(unsigned(READ_RIGHT_INDEX)));

end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.P_REGS.all;

entity programcounter is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		WRITE : in STD_LOGIC;
		INPUT : in T_REG;
		INCREMENT : in STD_LOGIC;
		OUTPUT : out T_REG
	);
end entity;

architecture behavioral of programcounter is
	signal PC : T_REG := DEFAULT_PC;
begin
	process (RESET, CLOCK)
	begin
		if (RESET = '1') then
--			report "PC is reseting";
			PC <= DEFAULT_PC;
		elsif (CLOCK'Event and CLOCK = '1') then
			if (WRITE = '1') then
				PC <= INPUT;
			else
				PC <= PC + INCREMENT;
			end if;

		end if;
	end process;

	OUTPUT <= PC;
end architecture;
