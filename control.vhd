library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_CONTROL is
	subtype T_OPCODE is STD_LOGIC_VECTOR (15 downto 0);

	constant OPCODE_NOP :		T_OPCODE := x"0000";

	constant OPCODE_JUMP :		T_OPCODE := "00000000" & "00001---";
	constant OPCODE_BRANCH :	T_OPCODE := "00000000" & "00011---";

	constant OPCODE_LOADI :		T_OPCODE := "00000000" & "00010---";
	constant OPCODE_STOREI :	T_OPCODE := "00000000" & "00100---";
	constant OPCODE_CLEAR :		T_OPCODE := "00000000" & "00110---";
	constant OPCODE_LOADR :		T_OPCODE := "00000000" & "01------";
	constant OPCODE_STORER :	T_OPCODE := "00000000" & "10------";

	constant OPCODE_ALU :		T_OPCODE := "0001----" & "00------";

	subtype T_FLOWTYPE is STD_LOGIC_VECTOR (1 downto 0);

	constant FLOWTYPE_ALWAYS :	T_FLOWTYPE := "00";
	constant FLOWTYPE_CARRY :	T_FLOWTYPE := "01";
	constant FLOWTYPE_ZERO :	T_FLOWTYPE := "10";
	constant FLOWTYPE_NEG :		T_FLOWTYPE := "11";

	type T_STATE is (
		S_FETCH1, S_FETCH2,
		S_FLOW1, S_FLOW_TAKEN1, S_FLOW_TAKEN2, S_FLOW_SKIP1,
		S_LOADI1, S_LOADI2, S_CLEAR1, S_STOREI1, S_STOREI2,
		S_LOADR1, S_LOADR2, S_STORER1,
		S_ALU1, S_ALU2
	);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_REGS.all;
use work.P_CONTROL.all;

entity control is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
		DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		READ : out STD_LOGIC;
		WRITE : out STD_LOGIC;
		
		ALU_DO_OP : out STD_LOGIC;
		ALU_OP : out T_ALU_OP;
		ALU_CARRY_IN : out STD_LOGIC;
		ALU_RESULT : in STD_LOGIC_VECTOR (15 downto 0);
		ALU_CARRY_OUT : in STD_LOGIC;
		ALU_ZERO_OUT : in STD_LOGIC;
		ALU_NEG_OUT : in STD_LOGIC;
		
		REGS_CLEAR : out STD_LOGIC;
		REGS_WRITE : out STD_LOGIC;
		REGS_WRITE_INDEX : out T_REG_INDEX;
		REGS_LEFT_INDEX : out T_REG_INDEX;
		REGS_RIGHT_INDEX : out T_REG_INDEX;
		REGS_LEFT_OUTPUT : in T_REG;
		REGS_RIGHT_OUTPUT : in T_REG;
		REGS_INPUT : out T_REG;
		
		PC_JUMP : out STD_LOGIC;
		PC_BRANCH : out STD_LOGIC;
		PC_INPUT : out T_REG;
		PC_INCREMENT : out STD_LOGIC;
		PC_OUTPUT : in T_REG
	);
end entity;

architecture behavioural of control is
	-- Shared
	signal OPCODE : T_OPCODE := (others => '0');
	signal STATE : T_STATE := S_FETCH1;
	alias FLOWTYPE : T_FLOWTYPE is OPCODE (2 downto 1);
	alias FLOW_POLARITY : STD_LOGIC is OPCODE (0);
begin
	ALU_OP <= OPCODE (11 downto 8);
	REGS_LEFT_INDEX <= OPCODE (5 downto 3);
	REGS_RIGHT_INDEX <= OPCODE (2 downto 0);

	process (RESET, CLOCK)
	begin
		if (RESET = '1') then
			STATE <= S_FETCH1;
			ALU_CARRY_IN <= '0';
			OPCODE <= OPCODE_NOP;
			PC_JUMP <= '0';
			PC_BRANCH <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			ALU_DO_OP <= '0';
			READ <= '0';
			WRITE <= '0';
		elsif (CLOCK'Event and CLOCK = '1') then
			READ <= '0';
			WRITE <= '0';
			PC_JUMP <= '0';
			PC_BRANCH <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			ALU_DO_OP <= '0';

			case STATE is
				when S_FETCH1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_FETCH2;

				when S_FETCH2 =>
					OPCODE <= T_OPCODE(DATA_IN);
--pragma synthesis_off
					report "CPU: Reading opcode " & to_hstring(OPCODE) & " from " & to_hstring(PC_OUTPUT);
--pragma synthesis_on
					case? DATA_IN is
						when OPCODE_NOP =>
							STATE <= S_FETCH1;

						when OPCODE_JUMP | OPCODE_BRANCH =>
							STATE <= S_FLOW1;

						when OPCODE_LOADI =>
							STATE <= S_LOADI1;

						when OPCODE_STOREI =>
							STATE <= S_STOREI1;

						when OPCODE_CLEAR =>
							STATE <= S_CLEAR1;

						when OPCODE_LOADR =>
							STATE <= S_LOADR1;

						when OPCODE_STORER =>
							STATE <= S_STORER1;

						when OPCODE_ALU =>
							ALU_DO_OP <= '1';
							STATE <= S_ALU1;

						when others =>
--pragma synthesis_off
							report "CPU: No opcode match!";
--pragma synthesis_on
							STATE <= S_FETCH1;
					end case?;

				when S_LOADI1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_LOADI2;

				when S_LOADI2 =>
					REGS_INPUT <= T_REG(DATA_IN);
					REGS_WRITE_INDEX <= REGS_RIGHT_INDEX;
					REGS_WRITE <= '1';
					STATE <= S_FETCH1;

				when S_STOREI1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_STOREI2;

				when S_STOREI2 =>
					ADDRESS <= DATA_IN;
					DATA_OUT <= STD_LOGIC_VECTOR(REGS_RIGHT_OUTPUT);
					WRITE <= '1';
					STATE <= S_FETCH1;

				when S_CLEAR1 =>
					REGS_WRITE_INDEX <= REGS_RIGHT_INDEX;
					REGS_CLEAR <= '1';
					STATE <= S_FETCH1;

				when S_LOADR1 =>
					ADDRESS <= REGS_LEFT_OUTPUT;
					READ <= '1';
					STATE <= S_LOADR2;

				when S_LOADR2 =>
					REGS_INPUT <= T_REG(DATA_IN);
					REGS_WRITE_INDEX <= REGS_RIGHT_INDEX;
					REGS_WRITE <= '1';
					STATE <= S_FETCH1;

				when S_STORER1 =>
--pragma synthesis_off
					report "CPU: STORER Address reg=" & to_hstring(REGS_LEFT_INDEX) & " (" & to_hstring(REGS_LEFT_OUTPUT) & ") Data reg=" &
						to_hstring(REGS_RIGHT_INDEX) & " (" & to_hstring(REGS_RIGHT_OUTPUT) & ")";
--pragma synthesis_on
					ADDRESS <= STD_LOGIC_VECTOR(REGS_LEFT_OUTPUT);
					DATA_OUT <= STD_LOGIC_VECTOR(REGS_RIGHT_OUTPUT);
					WRITE <= '1';
					STATE <= S_FETCH1;

				when S_FLOW1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
--pragma synthesis_off
					report "CPU: Jumping/Branching condition=" & to_string(FLOWTYPE) & " Polarity=" & STD_LOGIC'image(FLOW_POLARITY);
--pragma synthesis_on
					case FLOWTYPE is
						when FLOWTYPE_ALWAYS =>
							STATE <= S_FLOW_TAKEN1;

						when FLOWTYPE_CARRY =>
							if (ALU_CARRY_OUT = FLOW_POLARITY) then
								STATE <= S_FLOW_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_FLOW_SKIP1;
							end if;

						when FLOWTYPE_ZERO =>
							if (ALU_ZERO_OUT = FLOW_POLARITY) then
								STATE <= S_FLOW_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_FLOW_SKIP1;
							end if;

						when FLOWTYPE_NEG =>
							if (ALU_NEG_OUT = FLOW_POLARITY) then
								STATE <= S_FLOW_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_FLOW_SKIP1;
							end if;

						when others =>
							STATE <= S_FETCH1;
					end case;

				when S_FLOW_TAKEN1 =>
					PC_INPUT <= T_REG(DATA_IN);
					if (OPCODE (15 downto 3) = OPCODE_JUMP (15 downto 3)) then
						PC_JUMP <= '1';
					else
						PC_BRANCH <= '1';
					end if;
					STATE <= S_FLOW_TAKEN2;

				when S_FLOW_TAKEN2 =>
					STATE <= S_FETCH1;

				when S_FLOW_SKIP1 =>
					STATE <= S_FETCH1;

				when S_ALU1 =>
					STATE <= S_ALU2;

				when S_ALU2 =>
--pragma synthesis_off
					report "CPU: ALU OP " & to_hstring(ALU_OP) & " Operand reg=" & to_hstring(REGS_LEFT_INDEX) &
						" (" & to_hstring(REGS_LEFT_OUTPUT) & ") Dest reg=" & to_hstring(REGS_RIGHT_INDEX) &
						" (" & to_hstring(REGS_RIGHT_OUTPUT) & ")" & " Result=" & to_hstring(ALU_RESULT);
--pragma synthesis_on
					REGS_INPUT <= T_REG(ALU_RESULT);
					REGS_WRITE_INDEX <= REGS_RIGHT_INDEX;
					REGS_WRITE <= '1';
					ALU_CARRY_IN <= ALU_CARRY_OUT;
					STATE <= S_FETCH1;

				end case;
--pragma synthesis_off
				report "CPU: PC=" & to_hstring(PC_OUTPUT) & " Opcode=" & to_hstring(OPCODE) & " STATE=" & T_STATE'image(STATE);
--pragma synthesis_on
			end if;
	end process;
end architecture;
