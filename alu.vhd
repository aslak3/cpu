library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_ALU is
	subtype T_ALU_OP is STD_LOGIC_VECTOR (3 downto 0);

	constant OP_ADD :		T_ALU_OP := x"0";
	constant OP_ADDC :		T_ALU_OP := x"1";
	constant OP_SUB :		T_ALU_OP := x"2";
	constant OP_SUBC :		T_ALU_OP := x"3";
	constant OP_INC : 		T_ALU_OP := x"4";
	constant OP_DEC : 		T_ALU_OP := x"5";
	constant OP_AND :		T_ALU_OP := x"6";
	constant OP_OR : 		T_ALU_OP := x"7";
	constant OP_XOR : 		T_ALU_OP := x"8";
	constant OP_NOT : 		T_ALU_OP := x"9";
	constant OP_LEFT : 		T_ALU_OP := x"a";
	constant OP_RIGHT :	 	T_ALU_OP := x"b";
	constant OP_COPY :		T_ALU_OP := x"c";
	constant OP_NEG :		T_ALU_OP := x"d";
	constant OP_COMP :		T_ALU_OP := x"f";
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;

entity alu is
	port (
		CLOCK : STD_LOGIC;
		DO_OP : in STD_LOGIC;
		OP : in T_ALU_OP;
		LEFT, RIGHT : in STD_LOGIC_VECTOR (15 downto 0);
		CARRY_IN : in STD_LOGIC;
		RESULT : out STD_LOGIC_VECTOR (15 downto 0);
		CARRY_OUT : out STD_LOGIC;
		ZERO_OUT : out STD_LOGIC;
		NEG_OUT : out STD_LOGIC
	);
end entity;

architecture behavioural of alu is
	signal TEMP_LEFT  : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
	signal TEMP_RIGHT : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
	signal TEMP_RESUlT : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
	signal GIVE_RESULT : STD_LOGIC := '0';
begin
	TEMP_LEFT <= '0' & LEFT (15 downto 0);
	TEMP_RIGHT <= '0' & RIGHT (15 downto 0);

	process (CLOCK)
    begin
		if (CLOCK'Event and CLOCK = '1') then
			if (DO_OP = '1') then
				GIVE_RESULT <= '1';
				case OP is
					when OP_ADD =>
						TEMP_RESULT <= TEMP_RIGHT + TEMP_LEFT;
					when OP_ADDC =>
						TEMP_RESULT <= TEMP_RIGHT + TEMP_LEFT + CARRY_IN;
					when OP_SUB =>
						TEMP_RESULT <= TEMP_RIGHT - TEMP_LEFT;
					when OP_SUBC =>
						TEMP_RESULT <= TEMP_RIGHT - TEMP_LEFT - CARRY_IN;
					when OP_INC =>
						TEMP_RESULT <= TEMP_RIGHT + 1;
					when OP_DEC =>
						TEMP_RESULT <= TEMP_RIGHT - 1;
					when OP_AND =>
						TEMP_RESULT <= TEMP_RIGHT and TEMP_LEFT;
					when OP_OR =>
						TEMP_RESULT <= TEMP_RIGHT or TEMP_LEFT;
					when OP_XOR =>
						TEMP_RESULT <= TEMP_RIGHT xor TEMP_LEFT;
					when OP_NOT =>
						TEMP_RESULT <= not ('1' & TEMP_RIGHT (15 downto 0));
					when OP_LEFT =>
						TEMP_RESULT <= TEMP_RIGHT (15 downto 0) & '0';
					when OP_RIGHT =>
						TEMP_RESULT <= TEMP_RIGHT (0) & '0' & TEMP_RIGHT (15 downto 1);
					when OP_COPY =>
						TEMP_RESULT <= TEMP_LEFT;
					when OP_NEG =>
						TEMP_RESULT <= not TEMP_RIGHT + 1;
					when OP_COMP =>
						TEMP_RESULT <= TEMP_RIGHT - TEMP_LEFT;
						GIVE_RESULT <= '0';
					when others =>
						TEMP_RESULT <= (others => '0');
				end case;
--pragma synthesis_off
				report "ALU: OP " & to_hstring(OP) & " Operand=" &
					to_hstring(LEFT) & " Dest=" & to_hstring(RIGHT);
--pragma synthesis_on
			end if;
		end if;
	end process;

	RESULT <= TEMP_RESULT (15 downto 0) when (GIVE_RESULT = '1') else
		RIGHT;
	CARRY_OUT <= TEMP_RESULT (16);
	ZERO_OUT <= '1' when (TEMP_RESULT (15 downto 0) = x"0000") else '0';
	NEG_OUT <= TEMP_RESULT (15);
end architecture;
