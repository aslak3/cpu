library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_ALU is
	subtype T_ALU_OP is STD_LOGIC_VECTOR (4 downto 0);

	constant OP_ADD :			T_ALU_OP := '0' & x"0";
	constant OP_ADDC :			T_ALU_OP := '0' & x"1";
	constant OP_SUB :			T_ALU_OP := '0' & x"2";
	constant OP_SUBC :			T_ALU_OP := '0' & x"3";
	constant OP_AND :			T_ALU_OP := '0' & x"4";
	constant OP_OR : 			T_ALU_OP := '0' & x"5";
	constant OP_XOR : 			T_ALU_OP := '0' & x"6";
	constant OP_COPY :			T_ALU_OP := '0' & x"7";
	constant OP_COMP :			T_ALU_OP := '0' & x"8";
	constant OP_BIT :			T_ALU_OP := '0' & x"9";
	constant OP_MULU :			T_ALU_OP := '0' & x"a";
	constant OP_MULS :			T_ALU_OP := '0' & x"b";

	constant OP_INC : 			T_ALU_OP := '1' & x"0";
	constant OP_DEC : 			T_ALU_OP := '1' & x"1";
	constant OP_INCD : 			T_ALU_OP := '1' & x"2";
	constant OP_DECD : 			T_ALU_OP := '1' & x"3";
	constant OP_NOT : 			T_ALU_OP := '1' & x"4";
	constant OP_LOGIC_LEFT : 	T_ALU_OP := '1' & x"5";
	constant OP_LOGIC_RIGHT :	T_ALU_OP := '1' & x"6";
	constant OP_ARITH_LEFT : 	T_ALU_OP := '1' & x"7";
	constant OP_ARITH_RIGHT :	T_ALU_OP := '1' & x"8";
	constant OP_NEG :			T_ALU_OP := '1' & x"9";
	constant OP_SWAP :			T_ALU_OP := '1' & x"a";
	constant OP_TEST :			T_ALU_OP := '1' & x"b";

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
		NEG_OUT : out STD_LOGIC;
		OVER_OUT : out STD_LOGIC
	);
end entity;

architecture behavioural of alu is
begin
	process (CLOCK)
		variable TEMP_LEFT  : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
		variable TEMP_RIGHT : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
		variable TEMP_RESUlT : STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
		variable GIVE_RESULT : STD_LOGIC := '0';
    begin
		if (CLOCK'Event and CLOCK = '1') then
			if (DO_OP = '1') then
				GIVE_RESULT := '1';
				TEMP_LEFT := '0' & LEFT (15 downto 0);
				TEMP_RIGHT := '0' & RIGHT (15 downto 0);

				case OP is
					when OP_ADD =>
						TEMP_RESULT := TEMP_RIGHT + TEMP_LEFT;
					when OP_ADDC =>
						TEMP_RESULT := TEMP_RIGHT + TEMP_LEFT + CARRY_IN;
					when OP_SUB =>
						TEMP_RESULT := TEMP_RIGHT - TEMP_LEFT;
					when OP_SUBC =>
						TEMP_RESULT := TEMP_RIGHT - TEMP_LEFT - CARRY_IN;
					when OP_AND =>
						TEMP_RESULT := TEMP_RIGHT and TEMP_LEFT;
					when OP_OR =>
						TEMP_RESULT := TEMP_RIGHT or TEMP_LEFT;
					when OP_XOR =>
						TEMP_RESULT := TEMP_RIGHT xor TEMP_LEFT;
					when OP_COPY =>
						TEMP_RESULT := TEMP_LEFT;
					when OP_COMP =>
						TEMP_RESULT := TEMP_RIGHT - TEMP_LEFT;
						GIVE_RESULT := '0';
					when OP_BIT =>
						TEMP_RESULT := TEMP_RIGHT and TEMP_LEFT;
						GIVE_RESULT := '0';
					when OP_MULU =>
						TEMP_RESULT := '0' & STD_LOGIC_VECTOR(unsigned(TEMP_RIGHT (7 downto 0)) * unsigned(TEMP_LEFT (7 downto 0)));
					when OP_MULS =>
						TEMP_RESULT := '0' & STD_LOGIC_VECTOR(signed(TEMP_RIGHT (7 downto 0)) * signed(TEMP_LEFT (7 downto 0)));

					when OP_INC =>
						TEMP_RESULT := TEMP_RIGHT + 1;
					when OP_DEC =>
						TEMP_RESULT := TEMP_RIGHT - 1;
					when OP_INCD =>
						TEMP_RESULT := TEMP_RIGHT + 2;
					when OP_DECD =>
						TEMP_RESULT := TEMP_RIGHT - 2;
					when OP_NOT =>
						TEMP_RESULT := not ('1' & TEMP_RIGHT (15 downto 0));
					when OP_LOGIC_LEFT =>
						TEMP_RESULT := TEMP_RIGHT (15 downto 0) & '0';
					when OP_LOGIC_RIGHT =>
						TEMP_RESULT := TEMP_RIGHT (0) & '0' & TEMP_RIGHT (15 downto 1);
					when OP_ARITH_LEFT =>
						TEMP_RESULT := TEMP_RIGHT (15 downto 0) & '0';
					when OP_ARITH_RIGHT =>
						TEMP_RESULT := TEMP_RIGHT (0) & TEMP_RIGHT (15) & TEMP_RIGHT (15 downto 1);
					when OP_NEG =>
						TEMP_RESULT := not TEMP_RIGHT + 1;
					when OP_SWAP =>
						TEMP_RESULT := '0' & TEMP_RIGHT (7 downto 0) & TEMP_RIGHT (15 downto 8);
					when OP_TEST =>
						TEMP_RESULT := TEMP_RIGHT;
						GIVE_RESULT := '0';

					when others =>
						TEMP_RESULT := (others => '0');
				end case;

				if (GIVE_RESULT = '1') then
					RESULT <= TEMP_RESULT (15 downto 0);
				else
					RESULT <= RIGHT;
				end if;

				CARRY_OUT <= TEMP_RESULT (16);

				if (TEMP_RESULT (15 downto 0) = x"0000") then
					ZERO_OUT <= '1';
				else
					ZERO_OUT <= '0';
				end if;

				NEG_OUT <= TEMP_RESULT (15);

				-- When adding then if sign of result is different to the sign of both the
				-- operands then it is an overflow condition
				if (OP = OP_ADD or OP = OP_ADDC) then
					if (TEMP_LEFT (15) /= TEMP_RESULT (15) and TEMP_RIGHT (15) /= TEMP_RESULT (15)) then
						OVER_OUT <= '1';
					else
						OVER_OUT <= '0';
					end if;
				-- Likewise for sub, but invert the left sign for test as its a subtract
				elsif (OP = OP_SUB or OP = OP_SUBC) then
					if (TEMP_LEFT (15) = TEMP_RESULT (15) and TEMP_RIGHT (15) /= TEMP_RESULT (15)) then
						OVER_OUT <= '1';
					else
						OVER_OUT <= '0';
					end if;
				-- For arith shift left, if the sign changed then it is an overflow
				elsif (OP = OP_ARITH_LEFT) then
					if (TEMP_RIGHT (15) /= TEMP_RESULT (15)) then
						OVER_OUT <= '1';
					else
						OVER_OUT <= '0';
					end if;
				else
					OVER_OUT <= '0';
				end if;

--pragma synthesis_off
				report "ALU: OP " & to_hstring(OP) & " Operand=" &
					to_hstring(LEFT) & " Dest=" & to_hstring(RIGHT);
--pragma synthesis_on
			end if;
		end if;
	end process;
end architecture;
