library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clockdiv is
	port (
		CLOCK : in STD_LOGIC;
		CLOCK_MAIN : out STD_LOGIC
	);
end entity;

architecture behavioral of clockdiv is
	signal COUNTER : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
begin
	process (CLOCK)
	begin
		if (CLOCK'Event and CLOCK = '1') then
			COUNTER <= COUNTER + 1;
		end if;
	end process;
	CLOCK_MAIN <= COUNTER (2);
end architecture;
