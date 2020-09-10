library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Instruction format
--
-- Moves Source and Destination Register (with optional immediate displacement):
-- [Opcode: 15 downto 10][Source: 5 downto 3][Destination: 2 downto 0]
-- Moves Destination Register:
-- [Opcode: 15 downto 10][Destination: 2 downto 0]
-- Jump/Branch always:
-- [Opcode 15 downto 10]
-- Jump/Branch conditionally:
-- [Opcode 15 downto 10][Flags: 8 downto 6][Care: 5 downto 3][Polarity: 2 downto 0]
-- ALU Source and Destination Register
-- [Opcode 15 dowonto 10][Operation: 9 downto 6][Source: 5 downto 3][Destination: 2 downto 0]
-- ALU Destination Register only (or immediate source)
-- [Opcode 15 dowonto 10][Operation: 9 downto 6][Destination: 2 donwto 0]
-- Call and Return
-- [Opcode: 15 downto 10][Stack Pointer: 5 downto 3][Stack Pointer: 2 downto 0]

package P_CONTROL is
	subtype T_OPCODE is STD_LOGIC_VECTOR (5 downto 0);

	constant OPCODE_NOP :			T_OPCODE := "000000";

	constant OPCODE_JUMP :			T_OPCODE := "000010";
	constant OPCODE_BRANCH :		T_OPCODE := "000011";

	constant OPCODE_LOADI :			T_OPCODE := "001000";
	constant OPCODE_STOREI :		T_OPCODE := "001001";
	constant OPCODE_CLEAR :			T_OPCODE := "001100";
	constant OPCODE_LOADR :			T_OPCODE := "001010";
	constant OPCODE_STORER :		T_OPCODE := "001011";
	constant OPCODE_LOADRD :		T_OPCODE := "011010";
	constant OPCODE_STORERD :		T_OPCODE := "011011";

	constant OPCODE_ALU :			T_OPCODE := "001110";
	constant OPCODE_ALUI :			T_OPCODE := "001111";

	constant OPCODE_CALLJUMP :		T_OPCODE := "010000";
	constant OPCODE_CALLBRANCH :	T_OPCODE := "010001";
	constant OPCODE_RETURN :		T_OPCODE := "010010";

	constant OPCODE_PUSHQUICK :		T_OPCODE := "010100";
	constant OPCODE_POPQUICK :		T_OPCODE := "010101";
	constant OPCODE_PUSHMULTI :		T_OPCODE := "010110";
	constant OPCODE_POPMULTI :		T_OPCODE := "010111";

	subtype T_FLOWTYPE is STD_LOGIC_VECTOR (2 downto 0);

	constant FLOWTYPE_CARRY :	integer := 0;
	constant FLOWTYPE_ZERO :	integer := 1;
	constant FLOWTYPE_NEG :		integer := 2;

	type T_STATE is (
		S_FETCH1, S_FETCH2,
		S_FLOW1,
		S_LOADI1, S_STOREI1,
		S_LOADR1, S_STORER1, S_STOREI2,
		S_LOADRD1, S_LOADRD2, S_STORERD1, S_STORERD2,
		S_ALU1,
		S_CALL1, S_CALL2, S_RETURN1,
		S_PUSHQUICK1, S_POPQUICK1,
		S_PUSHMULTI1, S_PUSHMULTI2, S_POPMULTI1, S_POPMULTI2
	);

	type T_ALU_LEFT_MUX_SEL is
		( S_REGS_LEFT, S_DATA_IN );
	type T_ALU_RIGHT_MUX_SEL is
		( S_REGS_RIGHT, S_DATA_IN );
	type T_REGS_INPUT_MUX_SEL is
		( S_ALU_RESULT, S_REGS_RIGHT, S_TEMPORARY_OUTPUT, S_DATA_IN );
	type T_ADDRESS_MUX_SEL is
		( S_PC, S_REGS_LEFT, S_REGS_RIGHT, S_ALU_RESULT, S_TEMPORARY_OUTPUT, S_DATA_IN );
	type T_DATA_OUT_MUX_SEL is
		( S_PC, S_REGS_LEFT, S_REGS_RIGHT );

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
		DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		READ : out STD_LOGIC;
		WRITE : out STD_LOGIC;

		ALU_LEFT_MUX_SEL : out T_ALU_LEFT_MUX_SEL;
		ALU_RIGHT_MUX_SEL : out T_ALU_RIGHT_MUX_SEL;
		REGS_INPUT_MUX_SEL : out T_REGS_INPUT_MUX_SEL;
		ADDRESS_MUX_SEL : out T_ADDRESS_MUX_SEL;
		DATA_OUT_MUX_SEL : out T_DATA_OUT_MUX_SEL;

		ALU_DO_OP : out STD_LOGIC;
		ALU_OP : out T_ALU_OP;
		ALU_CARRY_IN : out STD_LOGIC;
		ALU_CARRY_OUT : in STD_LOGIC;
		ALU_ZERO_OUT : in STD_LOGIC;
		ALU_NEG_OUT : in STD_LOGIC;

		REGS_CLEAR : out STD_LOGIC;
		REGS_WRITE : out STD_LOGIC;
		REGS_INC : out STD_LOGIC;
		REGS_DEC : out STD_LOGIC;
		REGS_LEFT_INDEX : out T_REG_INDEX;
		REGS_RIGHT_INDEX : out T_REG_INDEX;

		PC_JUMP : out STD_LOGIC;
		PC_BRANCH : out STD_LOGIC;
		PC_INCREMENT : out STD_LOGIC;

		TEMPORARY_WRITE : out STD_LOGIC;
		TEMPORARY_OUTPUT : in T_REG
	);
end entity;

architecture behavioural of control is
	signal INSTRUCTION : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');

	-- Convience aliases for opcodes fields.
	alias OPCODE : T_OPCODE is INSTRUCTION (15 downto 10);
	alias FLOW_FLAGS : T_FLOWTYPE is INSTRUCTION (8 downto 6);
	alias FLOW_CARES : T_FLOWTYPE is INSTRUCTION (5 downto 3);
	alias FLOW_POLARITY : T_FLOWTYPE is INSTRUCTION (2 downto 0);

begin
	-- Continually assign the right and left ALU indexes from the instruction.
	REGS_LEFT_INDEX <= INSTRUCTION (5 downto 3);
	REGS_RIGHT_INDEX <= INSTRUCTION (2 downto 0);

	process (RESET, CLOCK)
		variable STATE : T_STATE := S_FETCH1;
		variable STACKED : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	begin
		if (RESET = '1') then
			STATE := S_FETCH1;

			ALU_LEFT_MUX_SEL <= S_REGS_LEFT;
			ALU_RIGHT_MUX_SEL <= S_REGS_RIGHT;
			REGS_INPUT_MUX_SEL <= S_REGS_RIGHT;
			ADDRESS_MUX_SEL <= S_PC;
			DATA_OUT_MUX_SEL <= S_REGS_RIGHT;

			INSTRUCTION <= (others => '0');
			ALU_CARRY_IN <= '0';
			PC_JUMP <= '0';
			PC_BRANCH <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			REGS_INC <= '0';
			REGS_DEC <= '0';
			ALU_DO_OP <= '0';
			READ <= '0';
			WRITE <= '0';
			TEMPORARY_WRITE <= '1';
		elsif (CLOCK'Event and CLOCK = '1') then
			READ <= '0';
			WRITE <= '0';
			PC_JUMP <= '0';
			PC_BRANCH <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			REGS_INC <= '0';
			REGS_DEC <= '0';
			ALU_DO_OP <= '0';
			TEMPORARY_WRITE <= '0';

			case STATE is
				when S_FETCH1 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE := S_FETCH2;

				when S_FETCH2 =>
					INSTRUCTION <= DATA_IN;
--pragma synthesis_off
					report "Control: Reading opcode " & to_string(DATA_IN (15 downto 10)) & " from " & T_ADDRESS_MUX_SEL'Image(ADDRESS_MUX_SEL);
--pragma synthesis_on
					case DATA_IN (15 downto 10) is
						when OPCODE_NOP =>
							STATE := S_FETCH1;

						when OPCODE_JUMP | OPCODE_BRANCH =>
							STATE := S_FLOW1;

						when OPCODE_LOADI =>
							STATE := S_LOADI1;

						when OPCODE_STOREI =>
							STATE := S_STOREI1;

						when OPCODE_CLEAR =>
							REGS_CLEAR <= '1';
							STATE := S_FETCH1;

						when OPCODE_LOADR =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							STATE := S_LOADR1;

						when OPCODE_STORER =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							DATA_OUT_MUX_SEL <= S_REGS_RIGHT;
							STATE := S_STORER1;

						when OPCODE_LOADRD =>
							STATE := S_LOADRD1;

						when OPCODE_STORERD =>
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							ALU_LEFT_MUX_SEL <= S_REGS_LEFT;
							ALU_RIGHT_MUX_SEL <= S_DATA_IN;
							ALU_OP <= OP_ADD;
							ALU_DO_OP <= '1';
							STATE := S_STORERD1;

						when OPCODE_ALU =>
							ALU_LEFT_MUX_SEL <= S_REGS_LEFT;
							ALU_RIGHT_MUX_SEL <= S_REGS_RIGHT;
							ALU_OP <= DATA_IN (9 downto 6);
							ALU_DO_OP <= '1';
							STATE := S_ALU1;

						when OPCODE_ALUI =>
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							ALU_LEFT_MUX_SEL <= S_DATA_IN;
							ALU_RIGHT_MUX_SEL <= S_REGS_RIGHT;
							ALU_DO_OP <= '1';
							ALU_OP <= DATA_IN (9 downto 6);
							STATE := S_ALU1;

						when OPCODE_CALLJUMP | OPCODE_CALLBRANCH =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							DATA_OUT_MUX_SEL <= S_PC;
							REGS_DEC <= '1';
							STATE := S_CALL1;

						when OPCODE_RETURN =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							STATE := S_RETURN1;

						when OPCODE_PUSHQUICK =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							DATA_OUT_MUX_SEL <= S_REGS_RIGHT;
							REGS_DEC <= '1';
							STATE := S_PUSHQUICK1;

						when OPCODE_POPQUICK =>
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							READ <= '1';
							STATE := S_POPQUICK1;

						when OPCODE_PUSHMULTI =>
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							STACKED := (others => '0');
							TEMPORARY_WRITE <= '1';
							STATE := S_PUSHMULTI1;

						when OPCODE_POPMULTI =>
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							STACKED := (others => '0');
							TEMPORARY_WRITE <= '1';
							STATE := S_POPMULTI1;

						when others =>
--pragma synthesis_off
							report "Control: No opcode match!";
--pragma synthesis_on
							STATE := S_FETCH1;
					end case;

				when S_LOADI1 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					PC_INCREMENT <= '1';
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					REGS_WRITE <= '1';
					STATE := S_FETCH1;

				when S_STOREI1 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					STATE := S_STOREI2;

				when S_STOREI2 =>
					ADDRESS_MUX_SEL <= S_DATA_IN;
					DATA_OUT_MUX_SEL <= S_REGS_RIGHT;
					WRITE <= '1';
					PC_INCREMENT <= '1';
					STATE := S_FETCH1;

				when S_LOADR1 =>
					READ <= '1';
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					REGS_WRITE <= '1';
					STATE := S_FETCH1;

				when S_STORER1 =>
					WRITE <= '1';
					STATE := S_FETCH1;

				when S_LOADRD1 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					ALU_LEFT_MUX_SEL <= S_REGS_LEFT;
					ALU_RIGHT_MUX_SEL <= S_DATA_IN;
					ALU_OP <= OP_ADD;
					ALU_DO_OP <= '1';
					STATE := S_LOADRD2;

				when S_LOADRD2 =>
					ADDRESS_MUX_SEL <= S_ALU_RESULT;
					READ <= '1';
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					REGS_WRITE <= '1';
					STATE := S_FETCH1;

				when S_STORERD1 =>
					PC_INCREMENT <= '1';
					ADDRESS_MUX_SEL <= S_ALU_RESULT;
					DATA_OUT_MUX_SEL <= S_REGS_RIGHT;
					STATE := S_STORERD2;

				when S_STORERD2 =>
					WRITE <= '1';
					STATE := S_FETCH1;

				when S_FLOW1 =>
--pragma synthesis_off
					report "Control: Jumping/Branching condition=" & to_string(FLOW_FLAGS) & " Cares=" & to_string(FLOW_CARES) & " Polarity=" & to_string(FLOW_POLARITY);
--pragma synthesis_on
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					if (
						( FLOW_CARES = "000" ) or
						(
						( ( FLOW_FLAGS(FLOWTYPE_CARRY) = '1' and FLOW_POLARITY(FLOWTYPE_CARRY) = ALU_CARRY_OUT ) or FLOW_CARES(FLOWTYPE_CARRY) = '0' ) and
						( ( FLOW_FLAGS(FLOWTYPE_ZERO) = '1' and FLOW_POLARITY(FLOWTYPE_ZERO) = ALU_ZERO_OUT ) or FLOW_CARES(FLOWTYPE_ZERO) = '0' ) and
						( ( FLOW_FLAGS(FLOWTYPE_NEG) = '1' and FLOW_POLARITY(FLOWTYPE_NEG) = ALU_NEG_OUT ) or FLOW_CARES(FLOWTYPE_NEG ) = '0' )
						)
					) then
						report "Control: Jump/Branch taken";
						if (OPCODE = OPCODE_JUMP) then
							PC_JUMP <= '1';
						else
							PC_BRANCH <= '1';
						end if;
					else
						report "Control: Jump/Branch NOT taken";
						PC_INCREMENT <= '1';
					end if;
					STATE := S_FETCH1;

				when S_ALU1 =>
					if (OPCODE = OPCODE_ALUI) then
						PC_INCREMENT <= '1';
					end if;
--pragma synthesis_off
					report "Control: ALU OP " & to_hstring(ALU_OP) & " Operand reg=" & to_hstring(REGS_LEFT_INDEX) &
						" Dest reg=" & to_hstring(REGS_RIGHT_INDEX) &
						" Regs Input Mux Sel=" & T_REGS_INPUT_MUX_SEL'Image(REGS_INPUT_MUX_SEL);
--pragma synthesis_on
					REGS_INPUT_MUX_SEL <= S_ALU_RESULT;
					REGS_WRITE <= '1';
					ALU_CARRY_IN <= ALU_CARRY_OUT;
					STATE := S_FETCH1;

				when S_CALL1 =>
					WRITE <= '1';
					STATE := S_CALL2;

				when S_CALL2 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					if (OPCODE = OPCODE_CALLJUMP) then
						PC_JUMP <= '1';
					else
						PC_BRANCH <= '1';
					end if;
					STATE := S_FETCH1;

				when S_RETURN1 =>
					READ <= '1';
					REGS_INC <= '1';
					PC_JUMP <= '1';
					STATE := S_FETCH1;

				when S_PUSHQUICK1 =>
					WRITE <= '1';
					STATE := S_FETCH1;

				when S_POPQUICK1 =>
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					REGS_WRITE <= '1';
					REGS_INC <= '1';
					STATE := S_FETCH1;

				when S_PUSHMULTI1 =>
					-- First cycle of a multi push is to decrement the stack pointer
					REGS_DEC <= '1';
					STATE := S_PUSHMULTI2;

				when S_PUSHMULTI2 =>
					-- Second cycle is the actual write
					for REG_NUMBER in 0 to 7 loop
						if (TEMPORARY_OUTPUT (REG_NUMBER) = '1' and STACKED (REG_NUMBER) = '0') then
							-- Get the first register we have not yet stacked: this has to be loaded
							-- into the instruction word
							INSTRUCTION (2 downto 0) <= STD_LOGIC_VECTOR (to_unsigned(REG_NUMBER, 3));
							-- Mark this register as stacked
							STACKED (REG_NUMBER) := '1';
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							DATA_OUT_MUX_SEL <= S_REGS_RIGHT;
							WRITE <= '1';
							exit;
						end if;
					end loop;
					-- When all are stacked, inc the PC and return to fetching, otherwise return
					-- to the decreemnting push multi state
					if (TEMPORARY_OUTPUT (7 downto 0) = STACKED) then
						PC_INCREMENT <= '1';
						STATE := S_FETCH1;
					else
						STATE := S_PUSHMULTI1;
					end if;

				when S_POPMULTI1 =>
					for REG_NUMBER in 7 downto 0 loop
						if (TEMPORARY_OUTPUT (REG_NUMBER) = '1' and STACKED (REG_NUMBER) = '0') then
							-- Get the first register we haven't yet unstacked. This is done in then
							-- reverse order to the push operation; the register to be unstacked is
							-- written into the instruction word at the right reg.
							INSTRUCTION (2 downto 0) <= STD_LOGIC_VECTOR (to_unsigned(REG_NUMBER, 3));
							STACKED (REG_NUMBER) := '1';
							ADDRESS_MUX_SEL <= S_REGS_LEFT;
							READ <= '1';
							REGS_INPUT_MUX_SEL <= S_DATA_IN;
							REGS_WRITE <= '1';
							exit;
						end if;
					end loop;
					STATE := S_POPMULTI2;

				when S_POPMULTI2 =>
					REGS_INC <= '1';
					if (TEMPORARY_OUTPUT (7 downto 0) = STACKED) then
						PC_INCREMENT <= '1';
						STATE := S_FETCH1;
					else
						STATE := S_POPMULTI1;
					end if;

			end case;
--pragma synthesis_off
			report "Control: Opcode=" & to_string(OPCODE) & " Params=" & to_string(INSTRUCTION (9 downto 0)) & " STATE=" & T_STATE'image(STATE);
--pragma synthesis_on
		end if;
	end process;
end architecture;
