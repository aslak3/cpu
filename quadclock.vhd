library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity quadclock is
	port (
		CLOCK : in STD_LOGIC;
		CLOCK_MAIN : out STD_LOGIC;
		CLOCK_DELAYED : out STD_LOGIC
	);
end entity;

architecture behavioral of quadclock is
	signal COUNTER : STD_LOGIC := '0';
begin
	process (CLOCK)
	begin
		if (CLOCK'Event and CLOCK = '1') then
			COUNTER <= not COUNTER;
		end if;
	end process;

	CLOCK_MAIN <= COUNTER;
	CLOCK_DELAYED <= COUNTER xor CLOCK;
end architecture;
