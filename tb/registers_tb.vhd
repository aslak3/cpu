library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGS.all;

entity registers_tb is
end entity;

architecture behavioral of registers_tb is
	signal CLOCK : STD_LOGIC := '0';
	signal RESET : STD_LOGIC := '0';
	signal REGS_CLEAR : STD_LOGIC := '0';
	signal REGS_WRITE : STD_LOGIC := '0';
	signal REGS_INC : STD_LOGIC := '0';
	signal REGS_DEC : STD_LOGIC := '0';
	signal REGS_READ_LEFT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_READ_RIGHT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_WRITE_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_INCDEC_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_LEFT_OUTPUT : T_REG;
	signal REGS_RIGHT_OUTPUT : T_REG;
	signal REGS_INPUT : T_REG := (others => '0');
begin
	dut: entity work.registers port map (
		CLOCK => CLOCK,
		RESET => RESET,
		CLEAR => REGS_CLEAR,
		WRITE => REGS_WRITE,
		INC => REGS_INC,
		DEC => REGS_DEC,
		READ_LEFT_INDEX => REGS_READ_LEFT_INDEX,
		READ_RIGHT_INDEX => REGS_READ_RIGHT_INDEX,
		WRITE_INDEX => REGS_WRITE_INDEX,
		INCDEC_INDEX => REGS_INCDEC_INDEX,
		LEFT_OUTPUT => REGS_LEFT_OUTPUT,
		RIGHT_OUTPUT => REGS_RIGHT_OUTPUT,
		INPUT => REGS_INPUT
	);

	process
		procedure clock_delay is
		begin
			CLOCK <= '0';
			wait for 1 ns;
			CLOCK <= '1';
			wait for 1 ns;
		end procedure;
	begin
		RESET <= '1';
		wait for 1 ns;
		RESET <= '0';

		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "001";

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"0000" and REGS_RIGHT_OUTPUT = x"0000"
			report "Reset failed" severity failure;

		REGS_INPUT <= x"1234";
		REGS_WRITE <= '1';
		REGS_WRITE_INDEX <= "000";

		clock_delay;

		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "000";
		REGS_WRITE <= '0';

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"1234" and REGS_RIGHT_OUTPUT = x"1234"
			report "Read/Write of reg 0 failed" severity failure;

		REGS_CLEAR <= '1';
		REGS_WRITE_INDEX <= "000";

		clock_delay;

		REGS_CLEAR <= '0';
		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "000";
		REGS_WRITE <= '0';

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"0000" and REGS_RIGHT_OUTPUT = x"0000"
			report "Read/Clear of reg 0 failed" severity failure;

		REGS_INC <= '1';
		REGS_INCDEC_INDEX <= "000";

		clock_delay;

		REGS_INC <= '0';
		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "000";
		REGS_WRITE <= '0';

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"0002" and REGS_RIGHT_OUTPUT = x"0002"
			report "Increment of reg 0 failed" severity failure;
		REGS_DEC <= '1';
		REGS_INCDEC_INDEX <= "000";

		clock_delay;

		REGS_DEC <= '0';
		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "000";
		REGS_WRITE <= '0';

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"0000" and REGS_RIGHT_OUTPUT = x"0000"
			report "Decrement of reg 0 failed" severity failure;

		REGS_INC <= '1';
		REGS_INCDEC_INDEX <= "000";
		REGS_WRITE <= '1';
		REGS_WRITE_INDEX <= "001";
		REGS_INPUT <= x"4321";

		clock_delay;

		REGS_INC <= '0';
		REGS_READ_LEFT_INDEX <= "000";
		REGS_READ_RIGHT_INDEX <= "001";
		REGS_WRITE <= '0';

		clock_delay;

		assert REGS_LEFT_OUTPUT = x"0002" and REGS_RIGHT_OUTPUT = x"4321"
			report "Simultainius increment of reg 0 / write of reg 1 failed" severity failure;

		report "+++All good";
		std.env.finish;
	end process;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGS.all;

entity programcounter_tb is
end entity;

architecture behavioral of programcounter_tb is
	signal CLOCK : STD_LOGIC;
	signal RESET : STD_LOGIC;
	signal PC_JUMP : STD_LOGIC := '0';
	signal PC_INPUT : T_REG := (others => '0');
	signal PC_INCREMENT : STD_LOGIC := '0';
	signal PC_OUTPUT : T_REG;
begin
	dut: entity work.programcounter port map (
		CLOCK => CLOCK,
		RESET => RESET,
		JUMP => PC_JUMP,
		INPUT => PC_INPUT,
		INCREMENT => PC_INCREMENT,
		OUTPUT => PC_OUTPUT
	);

	process
		procedure clock_delay is
		begin
			CLOCK <= '1';
			wait for 1 ns;
			CLOCK <= '0';
			wait for 1 ns;
		end procedure;
	begin
		RESET <= '1';
		wait for 1 ns;
		RESET <= '0';

		clock_delay;

		assert PC_OUTPUT = x"0000"
			report "PC reset" severity failure;

		PC_INCREMENT <= '1';
		clock_delay;
		PC_INCREMENT <= '0';

		assert PC_OUTPUT = x"0002"
			report "PC increment" severity failure;

		PC_JUMP <= '1';
		PC_INPUT <= x"1234";
		clock_delay;
		PC_JUMP <= '0';

		assert PC_OUTPUT = x"1234"
			report "PC jump" severity failure;

		clock_delay;

		report "+++All good";
		std.env.finish;
	end process;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGS.all;

entity temporary_tb is
end entity;

architecture behavioral of temporary_tb is
	signal CLOCK : STD_LOGIC;
	signal RESET : STD_LOGIC;
	signal TEMPORARY_WRITE : STD_LOGIC := '0';
	signal TEMPORARY_INPUT : T_REG := (others => '0');
	signal TEMPORARY_OUTPUT : T_REG;
begin
	dut: entity work.temporary port map (
		CLOCK => CLOCK,
		RESET => RESET,
		WRITE => TEMPORARY_WRITE,
		INPUT => TEMPORARY_INPUT,
		OUTPUT => TEMPORARY_OUTPUT
	);

	process
		procedure clock_delay is
		begin
			CLOCK <= '1';
			wait for 1 ns;
			CLOCK <= '0';
			wait for 1 ns;
		end procedure;
	begin
		RESET <= '1';
		wait for 1 ns;
		RESET <= '0';

		clock_delay;

		assert TEMPORARY_OUTPUT = x"0000"
			report "Temporary reset" severity failure;

		TEMPORARY_WRITE <= '1';
		TEMPORARY_INPUT <= x"1234";
		clock_delay;
		TEMPORARY_WRITE <= '0';

		assert TEMPORARY_OUTPUT = x"1234"
			report "Temporary set" severity failure;

		report "+++All good";
		std.env.finish;
	end process;
end architecture;
