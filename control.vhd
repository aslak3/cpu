library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Instruction format
--
-- Moves Source and Destination Register (with optional immediate displacement):
-- [Opcode: 15 downto 10][Byte: 9][Signed: 8][Source: 5 downto 3][Destination: 2 downto 0]
-- Moves Destination Register:
-- [Opcode: 15 downto 10][Byte: 9][Signed: 8][Destination: 2 downto 0]
-- Jump/Branch:
-- [Opcode 15 downto 10][Care: 7 downto 4][Polarity: 3 downto 0]
-- ALU Source and Destination Register
-- [Opcode 15 dowonto 10][Operation: 9 downto 6][Source: 5 downto 3][Destination: 2 downto 0]
-- ALU Destination Register only (or immediate source)
-- [Opcode 15 dowonto 10][Operation: 9 downto 6][Destination: 2 downto 0]
-- Call and Return
-- [Opcode: 15 downto 10][Stack Pointer: 5 downto 3][Stack Pointer: 2 downto 0]
-- Push/Pop Quick:
-- [Opcode 15 dowonto 10][Stack Pointer: 5 downto 3][Register: 2 downto 0]

package P_CONTROL is
	subtype T_OPCODE is STD_LOGIC_VECTOR (5 downto 0);

	constant OPCODE_NOP :			T_OPCODE := "000000";
	constant OPCODE_HALT :			T_OPCODE := "101010";

	constant OPCODE_JUMP :			T_OPCODE := "000010";
	constant OPCODE_BRANCH :		T_OPCODE := "000011";

	constant OPCODE_LOADI :			T_OPCODE := "000100";
	constant OPCODE_LOADM :			T_OPCODE := "001000";
	constant OPCODE_STOREM :		T_OPCODE := "001001";
	constant OPCODE_CLEAR :			T_OPCODE := "001100";
	constant OPCODE_LOADR :			T_OPCODE := "001010";
	constant OPCODE_STORER :		T_OPCODE := "001011";
	constant OPCODE_LOADRD :		T_OPCODE := "011010";
	constant OPCODE_STORERD :		T_OPCODE := "011011";

	constant OPCODE_ALUM :			T_OPCODE := "001110";
	constant OPCODE_ALUS :			T_OPCODE := "001111";
	constant OPCODE_ALUMI :			T_OPCODE := "011000";

	constant OPCODE_CALLJUMP :		T_OPCODE := "010000";
	constant OPCODE_CALLBRANCH :	T_OPCODE := "010001";
	constant OPCODE_RETURN :		T_OPCODE := "010010";

	constant OPCODE_PUSHQUICK :		T_OPCODE := "010100";
	constant OPCODE_POPQUICK :		T_OPCODE := "010101";

	subtype T_FLOWTYPE is STD_LOGIC_VECTOR (3 downto 0);
	constant FLOWTYPE_CARRY :		integer := 3;
	constant FLOWTYPE_ZERO :		integer := 2;
	constant FLOWTYPE_NEG :			integer := 1;
	constant FLOWTYPE_OVER :		integer := 0;

	subtype T_CYCLETYPE is STD_LOGIC_VECTOR (1 downto 0);
	constant CYCLETYPE_WORD :			T_CYCLETYPE := "00";
	constant CYCLETYPE_BYTE_UNSIGNED :	T_CYCLETYPE := "10";
	constant CYCLETYPE_BYTE_SIGNED :	T_CYCLETYPE := "11";

	type T_STATE is (
		S_ALU1,
		S_FETCH1, S_FETCH2,
		S_DECODE,
		S_HALT1,
		S_LOADM1, S_STOREM1,
		S_LOADRD1, S_STORERD1,
		S_BRANCH1,
		S_CALL1, S_CALL2,
		S_PUSHQUICK1, S_POPQUICK1
	);

	type T_ALU_LEFT_MUX_SEL is
		( S_PC, S_INSTRUCTION_LEFT, S_DATA_IN );
	type T_ALU_RIGHT_MUX_SEL is
		( S_INSTRUCTION_RIGHT, S_DATA_IN );
	type T_ALU_OP_MUX_SEL is
		( S_INSTRUCTION_ALU_OP, S_ADD );
	type T_REGS_INPUT_MUX_SEL is
		( S_ALU_RESULT, S_DATA_IN );
	type T_PC_INPUT_MUX_SEL is
		( S_ALU_RESULT, S_DATA_IN, S_TEMPORARY_OUTPUT );
	type T_TEMPORARY_INPUT_MUX_SEL is
		( S_ALU_RESULT, S_DATA_IN );
	type T_ADDRESS_MUX_SEL is
		( S_PC, S_INSTRUCTION_LEFT, S_ALU_RESULT, S_TEMPORARY_OUTPUT );
	type T_DATA_OUT_MUX_SEL is
		( S_PC, S_INSTRUCTION_RIGHT );

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
		CYCLETYPE : out T_CYCLETYPE;
		HALTED : out STD_LOGIC;

		ALU_LEFT_MUX_SEL : out T_ALU_LEFT_MUX_SEL;
		ALU_RIGHT_MUX_SEL : out T_ALU_RIGHT_MUX_SEL;
		ALU_OP_MUX_SEL : out T_ALU_OP_MUX_SEL;
		REGS_INPUT_MUX_SEL : out T_REGS_INPUT_MUX_SEL;
		PC_INPUT_MUX_SEL : out T_PC_INPUT_MUX_SEL;
		TEMPORARY_INPUT_MUX_SEL : out T_TEMPORARY_INPUT_MUX_SEL;
		ADDRESS_MUX_SEL : out T_ADDRESS_MUX_SEL;
		DATA_OUT_MUX_SEL : out T_DATA_OUT_MUX_SEL;

		INSTRUCTION_WRITE : out STD_LOGIC;
		INSTRUCTION_OPCODE : in T_OPCODE;
		INSTRUCTION_PARAMS : in STD_LOGIC_VECTOR (9 downto 0);
		INSTRUCTION_FLOW_CARES : in T_FLOWTYPE;
		INSTRUCTION_FLOW_POLARITY : in T_FLOWTYPE;
		INSTRUCTION_CYCLETYPE : in T_CYCLETYPE;

		ALU_CARRY_IN : out STD_LOGIC;
		ALU_CARRY_OUT : in STD_LOGIC;
		ALU_ZERO_OUT : in STD_LOGIC;
		ALU_NEG_OUT : in STD_LOGIC;
		ALU_OVER_OUT : in STD_LOGIC;

		REGS_CLEAR : out STD_LOGIC;
		REGS_WRITE : out STD_LOGIC;
		REGS_INC : out STD_LOGIC;
		REGS_DEC : out STD_LOGIC;

		PC_JUMP : out STD_LOGIC;
		PC_INCREMENT : out STD_LOGIC;

		TEMPORARY_WRITE : out STD_LOGIC;
		TEMPORARY_OUTPUT : in T_REG
	);
end entity;

architecture behavioural of control is
begin
	process (RESET, CLOCK)
		variable STATE : T_STATE := S_FETCH1;
		variable LAST_ALU_CARRY_OUT : STD_LOGIC := '0';
		variable LAST_ALU_ZERO_OUT : STD_LOGIC := '0';
		variable LAST_ALU_NEG_OUT : STD_LOGIC := '0';
		variable LAST_ALU_OVER_OUT : STD_LOGIC := '0';
	begin
		if (RESET = '1') then
			STATE := S_FETCH1;

			ALU_LEFT_MUX_SEL <= S_INSTRUCTION_LEFT;
			ALU_RIGHT_MUX_SEL <= S_INSTRUCTION_RIGHT;
			ALU_OP_MUX_SEL <= S_INSTRUCTION_ALU_OP;
			REGS_INPUT_MUX_SEL <= S_ALU_RESULT;
			PC_INPUT_MUX_SEL <= S_DATA_IN;
			ADDRESS_MUX_SEL <= S_PC;
			DATA_OUT_MUX_SEL <= S_PC;

			ALU_CARRY_IN <= '0';
			CYCLETYPE <= CYCLETYPE_WORD;

			READ <= '0';
			WRITE <= '0';
			INSTRUCTION_WRITE <= '0';
			PC_JUMP <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			REGS_INC <= '0';
			REGS_DEC <= '0';
			TEMPORARY_WRITE <= '0';
			HALTED <= '0';
		elsif (CLOCK'Event and CLOCK = '1') then
			READ <= '0';
			WRITE <= '0';
			INSTRUCTION_WRITE <= '0';
			PC_JUMP <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			REGS_INC <= '0';
			REGS_DEC <= '0';
			TEMPORARY_WRITE <= '0';

			case STATE is
				when S_FETCH1 =>
					report "In S_FETCH1";
					ADDRESS_MUX_SEL <= S_PC;
					CYCLETYPE <= CYCLETYPE_WORD;
					READ <= '1';
					PC_INCREMENT <= '1';
					INSTRUCTION_WRITE <= '1';
					STATE := S_FETCH2;

				when S_FETCH2 =>
					report "In S_FETCH2";
					STATE := S_DECODE;

				when S_DECODE =>
					case INSTRUCTION_OPCODE is
						when OPCODE_NOP =>
							report "Control: Opcode NOP";
							STATE := S_FETCH1;

						when OPCODE_HALT =>
							HALTED <= '1';
							STATE := S_HALT1;

						when OPCODE_LOADI =>
							report "Control: Opcode LOADI";
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							PC_INCREMENT <= '1';
							REGS_INPUT_MUX_SEL <= S_DATA_IN;
							REGS_WRITE <= '1';
							STATE := S_FETCH1;

						when OPCODE_LOADM =>
							report "Control: Opcode LOADM";
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							TEMPORARY_INPUT_MUX_SEL <= S_DATA_IN;
							TEMPORARY_WRITE <= '1';
							STATE := S_LOADM1;

						when OPCODE_STOREM =>
							report "Control: Opcode STOREM";
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							TEMPORARY_INPUT_MUX_SEL <= S_DATA_IN;
							TEMPORARY_WRITE <= '1';
							STATE := S_STOREM1;

						when OPCODE_CLEAR =>
							report "Control: Opcode CLEAR";
							REGS_CLEAR <= '1';
							STATE := S_FETCH1;

						when OPCODE_LOADR =>
							report "Control: Opcode LOADR";
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							READ <= '1';
							CYCLETYPE <= INSTRUCTION_CYCLETYPE;
							REGS_INPUT_MUX_SEL <= S_DATA_IN;
							REGS_WRITE <= '1';
							STATE := S_FETCH1;

						when OPCODE_STORER =>
							report "Control: Opcode STORER";
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							DATA_OUT_MUX_SEL <= S_INSTRUCTION_RIGHT;
							WRITE <= '1';
							CYCLETYPE <= INSTRUCTION_CYCLETYPE;
							STATE := S_FETCH1;

						when OPCODE_LOADRD =>
							report "Control: Opcode LOADRD";
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							ALU_LEFT_MUX_SEL <= S_INSTRUCTION_LEFT;
							ALU_RIGHT_MUX_SEL <= S_DATA_IN;
							ALU_OP_MUX_SEL <= S_ADD;
							TEMPORARY_INPUT_MUX_SEL <= S_ALU_RESULT;
							TEMPORARY_WRITE <= '1';
							STATE := S_LOADRD1;

						when OPCODE_STORERD =>
							report "Control: Opcode STORERD";
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
							ALU_LEFT_MUX_SEL <= S_INSTRUCTION_LEFT;
							ALU_RIGHT_MUX_SEL <= S_DATA_IN;
							ALU_OP_MUX_SEL <= S_ADD;
							TEMPORARY_INPUT_MUX_SEL <= S_ALU_RESULT;
							TEMPORARY_WRITE <= '1';
							STATE := S_STORERD1;

						when OPCODE_JUMP | OPCODE_BRANCH =>
							if (INSTRUCTION_OPCODE = OPCODE_JUMP) then
								report "Control: Opcode JUMP";
							else
								report "Control: Opcode BRANCH";
							end if;
							ADDRESS_MUX_SEL <= S_PC;
							READ <= '1';
--pragma synthesis_off
							report "Control: Jumping/Branching: Cares=" & to_string(INSTRUCTION_FLOW_CARES) & " Polarity=" & to_string(INSTRUCTION_FLOW_POLARITY);
--pragma synthesis_on
							if (
								( INSTRUCTION_FLOW_CARES = "0000" ) or
								(
								( ( INSTRUCTION_FLOW_POLARITY(FLOWTYPE_CARRY) = LAST_ALU_CARRY_OUT ) or INSTRUCTION_FLOW_CARES(FLOWTYPE_CARRY) = '0' ) and
								( ( INSTRUCTION_FLOW_POLARITY(FLOWTYPE_ZERO) = LAST_ALU_ZERO_OUT ) or INSTRUCTION_FLOW_CARES(FLOWTYPE_ZERO) = '0' ) and
								( ( INSTRUCTION_FLOW_POLARITY(FLOWTYPE_NEG) = LAST_ALU_NEG_OUT ) or INSTRUCTION_FLOW_CARES(FLOWTYPE_NEG ) = '0' ) and
								( ( INSTRUCTION_FLOW_POLARITY(FLOWTYPE_OVER) = LAST_ALU_OVER_OUT ) or INSTRUCTION_FLOW_CARES(FLOWTYPE_OVER ) = '0' )
								)
							) then
								if (INSTRUCTION_OPCODE = OPCODE_JUMP) then
									report "Control: Jump taken";
									PC_INPUT_MUX_SEL <= S_DATA_IN;
									PC_JUMP <= '1';
									STATE := S_FETCH1;
								else
									report "Control: Branch taken";
									ALU_LEFT_MUX_SEL <= S_PC;
									ALU_RIGHT_MUX_SEL <= S_DATA_IN;
									ALU_OP_MUX_SEL <= S_ADD;
									TEMPORARY_INPUT_MUX_SEL <= S_ALU_RESULT;
									TEMPORARY_WRITE <= '1';
									STATE := S_BRANCH1;
								end if;
							else
								report "Control: Jump/Branch NOT taken";
								PC_INCREMENT <= '1';
								STATE := S_FETCH1;
							end if;

						when OPCODE_ALUM | OPCODE_ALUS | OPCODE_ALUMI =>
							if (INSTRUCTION_OPCODE = OPCODE_ALUMI) then
								report "Control: Opcode ALUMI";
								PC_INCREMENT <= '1';
								READ <= '1';
								ALU_LEFT_MUX_SEL <= S_DATA_IN;
							else
								report "Control: Opcode ALUM/ALUS";
								ALU_LEFT_MUX_SEL <= S_INSTRUCTION_LEFT;
							end if;
							ALU_RIGHT_MUX_SEL <= S_INSTRUCTION_RIGHT;
							ALU_OP_MUX_SEL <= S_INSTRUCTION_ALU_OP;
							REGS_INPUT_MUX_SEL <= S_ALU_RESULT;
							REGS_WRITE <= '1';
							ALU_CARRY_IN <= ALU_CARRY_OUT;
							STATE := S_ALU1;

						when OPCODE_CALLJUMP | OPCODE_CALLBRANCH =>
							if (INSTRUCTION_OPCODE = OPCODE_CALLJUMP) then
								report "Control: Opcode CALLJUMP";
							else
								report "Control: Opcode CALLBRANCH";
							end if;
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							DATA_OUT_MUX_SEL <= S_PC;
							REGS_DEC <= '1';
							STATE := S_CALL1;

						when OPCODE_RETURN =>
							report "Control: Opcode RETURN";
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							READ <= '1';
							REGS_INC <= '1';
							PC_INPUT_MUX_SEL <= S_DATA_IN;
							PC_JUMP <= '1';
							STATE := S_FETCH1;

						when OPCODE_PUSHQUICK =>
							report "Control: Opcode PUSHQUICK";
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							DATA_OUT_MUX_SEL <= S_INSTRUCTION_RIGHT;
							REGS_DEC <= '1';
							STATE := S_PUSHQUICK1;

						when OPCODE_POPQUICK =>
							report "Control: Opcode POPQUICK";
							ADDRESS_MUX_SEL <= S_INSTRUCTION_LEFT;
							READ <= '1';
							REGS_INPUT_MUX_SEL <= S_DATA_IN;
							REGS_WRITE <= '1';
							STATE := S_POPQUICK1;

						when others =>
							report "Control: No opcode match!";
--pragma synthesis_off
							std.env.finish;
--pragma synthesis_on
							STATE := S_FETCH1;
					end case;


				when S_HALT1 =>
					STATE := S_HALT1;

				when S_LOADM1 =>
					ADDRESS_MUX_SEL <= S_TEMPORARY_OUTPUT;
					READ <= '1';
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					PC_INCREMENT <= '1';
					CYCLETYPE <= INSTRUCTION_CYCLETYPE;
					REGS_WRITE <= '1';
					STATE := S_FETCH1;

				when S_STOREM1 =>
					ADDRESS_MUX_SEL <= S_TEMPORARY_OUTPUT;
					DATA_OUT_MUX_SEL <= S_INSTRUCTION_RIGHT;
						WRITE <= '1';
					CYCLETYPE <= INSTRUCTION_CYCLETYPE;
					PC_INCREMENT <= '1';
					STATE := S_FETCH1;

				when S_LOADRD1 =>
					ADDRESS_MUX_SEL <= S_TEMPORARY_OUTPUT;
					READ <= '1';
					CYCLETYPE <= INSTRUCTION_CYCLETYPE;
					REGS_INPUT_MUX_SEL <= S_DATA_IN;
					REGS_WRITE <= '1';
					PC_INCREMENT <= '1';
					STATE := S_FETCH1;

				when S_STORERD1 =>
					ADDRESS_MUX_SEL <= S_TEMPORARY_OUTPUT;
					DATA_OUT_MUX_SEL <= S_INSTRUCTION_RIGHT;
					WRITE <= '1';
					CYCLETYPE <= INSTRUCTION_CYCLETYPE;
					PC_INCREMENT <= '1';
					STATE := S_FETCH1;

				when S_ALU1 =>
					LAST_ALU_CARRY_OUT := ALU_CARRY_OUT;
					LAST_ALU_ZERO_OUT := ALU_ZERO_OUT;
					LAST_ALU_NEG_OUT := ALU_NEG_OUT;
					LAST_ALU_OVER_OUT := ALU_OVER_OUT;
					ALU_CARRY_IN <= ALU_CARRY_OUT;
					STATE := S_FETCH1;

				when S_BRANCH1 =>
					PC_INPUT_MUX_SEL <= S_TEMPORARY_OUTPUT;
					PC_JUMP <= '1';
					STATE := S_FETCH1;

				when S_CALL1 =>
					WRITE <= '1';
					STATE := S_CALL2;

				when S_CALL2 =>
					ADDRESS_MUX_SEL <= S_PC;
					READ <= '1';
					if (INSTRUCTION_OPCODE = OPCODE_CALLJUMP) then
						PC_INPUT_MUX_SEL <= S_DATA_IN;
					else
						ALU_LEFT_MUX_SEL <= S_PC;
						ALU_RIGHT_MUX_SEL <= S_DATA_IN;
						ALU_OP_MUX_SEL <= S_ADD;
						PC_INPUT_MUX_SEL <= S_ALU_RESULT;
					end if;
					PC_JUMP <= '1';
					STATE := S_FETCH1;

				when S_PUSHQUICK1 =>
					WRITE <= '1';
					STATE := S_FETCH1;

				when S_POPQUICK1 =>
					REGS_INC <= '1';
					STATE := S_FETCH1;
			end case;
		end if;
	end process;
end architecture;
