library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_CPU is
	subtype T_OPCODE is STD_LOGIC_VECTOR (15 downto 0);

	constant OPCODE_NOP :		T_OPCODE := x"0000";
	
	constant OPCODE_JUMP :		T_OPCODE := "00000000" & "00001---";
	constant OPCODE_JUMPA :		T_OPCODE := "00000000" & "0000100-";
	constant OPCODE_JUMPC :		T_OPCODE := "00000000" & "0000101-";
	constant OPCODE_JUMPZ :		T_OPCODE := "00000000" & "0000110-";
	constant OPCODE_JUMPN 	:	T_OPCODE := "00000000" & "0000111-";
	
	constant OPCODE_LOADI :		T_OPCODE := "00000000" & "00010---";
	constant OPCODE_STOREI :	T_OPCODE := "00000000" & "00100---";
	constant OPCODE_LOADR :		T_OPCODE := "00000000" & "01------";
	constant OPCODE_STORER :	T_OPCODE := "00000000" & "10------";
	
	constant OPCODE_ALU :		T_OPCODE := "0001----" & "00------";
	constant OPCODE_ADD :		T_OPCODE := "00010000" & "00------";
	constant OPCODE_ADDC :		T_OPCODE := "00010001" & "00------";
	constant OPCODE_SUB :		T_OPCODE := "00010010" & "00------";
	constant OPCODE_SUBC :		T_OPCODE := "00010011" & "00------";
	constant OPCODE_INC :		T_OPCODE := "00010100" & "00------";
	constant OPCODE_INCD :		T_OPCODE := "00010101" & "00------";
	constant OPCODE_DEC :		T_OPCODE := "00010110" & "00------";
	constant OPCODE_DECD :		T_OPCODE := "00010111" & "00------";
	constant OPCODE_AND :		T_OPCODE := "00011000" & "00------";
	constant OPCODE_OR :		T_OPCODE := "00011001" & "00------";
	constant OPCODE_XOR :		T_OPCODE := "00011010" & "00------";
	constant OPCODE_NOT :		T_OPCODE := "00011011" & "00------";
	constant OPCODE_LEFT :		T_OPCODE := "00011100" & "00------";
	constant OPCODE_RIGHT :		T_OPCODE := "00011101" & "00------";
	
	subtype T_JUMPTYPE is STD_LOGIC_VECTOR (1 downto 0);
	
	constant JUMPTYPE_ALWAYS :	T_JUMPTYPE := "00";
	constant JUMPTYPE_CARRY :	T_JUMPTYPE := "01";
	constant JUMPTYPE_ZERO :	T_JUMPTYPE := "10";
	constant JUMPTYPE_NEG :		T_JUMPTYPE := "11";
	
	type T_STATE is (
		S_FETCH1, S_FETCH2,
		S_NOP1,
		S_JUMP1, S_JUMP2, S_JUMP_TAKEN1, S_JUMP_TAKEN2, S_JUMP_SKIP1,
		S_LOADI1, S_LOADI2, S_LOADI3, S_STOREI1, S_STOREI2, S_STOREI3,
		S_LOADR1, S_LOADR2, S_STORER1, S_STORER2,
		S_ALU1, S_ALU2
	);
end package;
	
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_REGS.all;
use work.P_CPU.all;

entity cpu is
	port (
		CLOCK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		ADDRESS : out STD_LOGIC_VECTOR (15 downto 0);
		DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		READ : out STD_LOGIC;
		WRITE : out STD_LOGIC
		);
end entity;

architecture behavioural of cpu is
	-- Shared
	signal LEFT, RIGHT : STD_LOGIC_VECTOR (15 downto 0);  -- inputs 
	signal OPCODE : T_OPCODE;
	alias OP : T_ALU_OP is OPCODE (11 downto 8);
	alias LEFT_INDEX : T_REG_INDEX is OPCODE (5 downto 3);
	alias RIGHT_INDEX : T_REG_INDEX is OPCODE (2 downto 0);
	alias JUMPTYPE : T_JUMPTYPE is OPCODE (2 downto 1);
	alias JUMP_POLARITY : STD_LOGIC is OPCODE (0);
	signal STATE : T_STATE := S_FETCH1;

	-- ALU
	signal ALU_DO_OP : STD_LOGIC;
	signal ALU_CARRY_IN : STD_LOGIC ;
	signal ALU_RESULT : STD_LOGIC_VECTOR (15 downto 0);  -- outputs
	signal ALU_CARRY_OUT : STD_LOGIC;
	signal ALU_ZERO_OUT : STD_LOGIC;
	signal ALU_NEG_OUT : STD_LOGIC;

	-- Registers
	signal REGS_WRITE : STD_LOGIC;
	signal REGS_WRITE_INDEX : T_REG_INDEX;
	signal REGS_INPUT : T_REG;	

	-- PC
	signal PC_WRITE : STD_LOGIC;
	signal PC_INPUT : T_REG;
	signal PC_INCREMENT : STD_LOGIC;
	signal PC_OUTPUT : T_REG;
begin
	alu: entity work.alu port map (
		CLOCK => CLOCK,
		DO_OP => ALU_DO_OP,
		OP => OP,
		LEFT => LEFT,
		RIGHT => RIGHT,
		CARRY_IN => ALU_CARRY_IN,
		RESULT => ALU_RESULT,
		CARRY_OUT => ALU_CARRY_OUT,
		ZERO_OUT => ALU_ZERO_OUT,
		NEG_OUT => ALU_NEG_OUT
	);

	registers: entity work.registers port map (
		CLOCK => CLOCK,
		RESET => RESET,
		WRITE => REGS_WRITE,
		READ_LEFT_INDEX => LEFT_INDEX,
		READ_RIGHT_INDEX => RIGHT_INDEX,
		WRITE_INDEX => REGS_WRITE_INDEX,
		LEFT_OUTPUT => LEFT,
		RIGHT_OUTPUT => RIGHT,
		INPUT => REGS_INPUT
	);
	
	programcounter: entity work.programcounter port map (
		CLOCK => CLOCK,
		RESET => RESET,
		WRITE => PC_WRITE,
		INPUT => PC_INPUT,
		INCREMENT => PC_INCREMENT,
		OUTPUT => PC_OUTPUT
	);	
	
	process (RESET, CLOCK)
	begin
		if (RESET = '1') then
			STATE <= S_FETCH1;
			ALU_CARRY_IN <= '0';
			OPCODE <= OPCODE_NOP;
			PC_WRITE <= '0';
			PC_INCREMENT <= '0';
			REGS_WRITE <= '0';
			ALU_DO_OP <= '0';
			READ <= '0';
			WRITE <= '0';
		elsif (CLOCK'Event and CLOCK = '1') then
			READ <= '0';
			WRITE <= '0';
			PC_WRITE <= '0';
			PC_INCREMENT <= '0';
			REGS_WRITE <= '0';
			ALU_DO_OP <= '0';
						
			case STATE is
				when S_FETCH1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					STATE <= S_FETCH2;

				when S_FETCH2 =>
					OPCODE <= T_OPCODE(DATA_IN);
					PC_INCREMENT <= '1';
					--report "CPU: Reading opcode " & to_hstring(OPCODE) & " from " & to_hstring(PC_OUTPUT);

					case? DATA_IN is
						when OPCODE_NOP =>
							STATE <= S_NOP1;

						when OPCODE_LOADI =>
							STATE <= S_LOADI1;

						when OPCODE_STOREI =>
							ADDRESS <= PC_OUTPUT;
							READ <= '1';
							STATE <= S_STOREI1;
	
						when OPCODE_LOADR =>
							STATE <= S_LOADR1;
							
						when OPCODE_STORER =>
							STATE <= S_STORER1;
					
						when OPCODE_JUMP =>
							STATE <= S_JUMP1;
							
						when OPCODE_ALU =>
							ALU_DO_OP <= '1';
							STATE <= S_ALU1;

						when others =>
							report "CPU: No opcode match!";
							STATE <= S_FETCH1;
					end case?;
					
				when S_NOP1 =>
					STATE <= S_FETCH1;

				when S_LOADI1 =>
					STATE <= S_LOADI2;
					
				when S_LOADI2 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_LOADI3;
					
				when S_LOADI3 =>
					REGS_INPUT <= T_REG(DATA_IN);
					REGS_WRITE_INDEX <= RIGHT_INDEX;
					REGS_WRITE <= '1';
					STATE <= S_FETCH1;
				
				when S_STOREI1 =>
					STATE <= S_STOREI2;
					
				when S_STOREI2 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_STOREI3;
				
				when S_STOREI3 =>
					ADDRESS <= DATA_IN;
					DATA_OUT <= STD_LOGIC_VECTOR(RIGHT);
					WRITE <= '1';
					STATE <= S_FETCH1;
				
				when S_LOADR1 =>
					ADDRESS <= LEFT;
					READ <= '1';
					STATE <= S_LOADR2;
							
				when S_LOADR2 =>
					REGS_INPUT <= T_REG(DATA_IN);
					REGS_WRITE_INDEX <= RIGHT_INDEX;
					REGS_WRITE <= '1';
					STATE <= S_FETCH1;

				when S_STORER1 =>
					STATE <= S_STORER2;

				when S_STORER2 =>
					report "CPU: STORER Address reg=" & to_hstring(LEFT_INDEX) & " (" & to_hstring(LEFT) & ") Data reg=" &
						to_hstring(RIGHT_INDEX) & " (" & to_hstring(RIGHT) & ")";
					ADDRESS <= STD_LOGIC_VECTOR(LEFT);
					DATA_OUT <= STD_LOGIC_VECTOR(RIGHT);
					WRITE <= '1';
					STATE <= S_FETCH1;
					
				when S_JUMP1 =>
					STATE <= S_JUMP2;

				when S_JUMP2 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					report "CPU: Jumping condition=" & to_string(JUMPTYPE) & " Polarity=" & STD_LOGIC'image(JUMP_POLARITY);
					
					case JUMPTYPE is
						when JUMPTYPE_ALWAYS =>
							STATE <= S_JUMP_TAKEN1;
						
						when JUMPTYPE_CARRY =>
							if (ALU_CARRY_OUT = JUMP_POLARITY) then
								STATE <= S_JUMP_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_JUMP_SKIP1;
							end if;

						when JUMPTYPE_ZERO =>
							if (ALU_ZERO_OUT = JUMP_POLARITY) then
								STATE <= S_JUMP_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_JUMP_SKIP1;
							end if;

						when JUMPTYPE_NEG =>
							if (ALU_NEG_OUT = JUMP_POLARITY) then
								STATE <= S_JUMP_TAKEN1;
							else
								PC_INCREMENT <= '1';
								STATE <= S_JUMP_SKIP1;
							end if;
						
						when others =>
							STATE <= S_FETCH1;
					end case;
				
				when S_JUMP_TAKEN1 =>
					PC_INPUT <= T_REG(DATA_IN);
					PC_WRITE <= '1';
					STATE <= S_JUMP_TAKEN2;
				
				when S_JUMP_TAKEN2 =>
					STATE <= S_FETCH1;
					
				when S_JUMP_SKIP1 =>
					STATE <= S_FETCH1;
				
				when S_ALU1 =>
					STATE <= S_ALU2;
					
				when S_ALU2 =>
					report "CPU: ALU OP " & to_hstring(OP) & " Operand reg=" & to_hstring(LEFT_INDEX) & " (" & to_hstring(LEFT) & ") Dest reg=" & to_hstring(RIGHT_INDEX) & " (" & to_hstring(RIGHT) & ")" &
					" Result=" & to_hstring(ALU_RESULT);
					REGS_INPUT <= T_REG(ALU_RESULT);
					REGS_WRITE_INDEX <= RIGHT_INDEX;
					REGS_WRITE <= '1';
					ALU_CARRY_IN <= ALU_CARRY_OUT;
					STATE <= S_FETCH1;
					
			end case;
			report "CPU: PC=" & to_hstring(PC_OUTPUT) & " Opcode=" & to_hstring(OPCODE) &
				" STATE=" & T_STATE'image(STATE);
		end if;
	end process;
end architecture;
