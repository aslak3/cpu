library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_CPU is
	subtype T_OPCODE is STD_LOGIC_VECTOR (15 downto 0);

	constant OPCODE_NOP :		T_OPCODE := x"0000";

	constant OPCODE_JUMP :		T_OPCODE := "00000000" & "00001---";
	constant OPCODE_BRANCH :	T_OPCODE := "00000000" & "00011---";

	constant OPCODE_LOADI :		T_OPCODE := "00000000" & "00010---";
	constant OPCODE_STOREI :	T_OPCODE := "00000000" & "00100---";
	constant OPCODE_CLEAR :		T_OPCODE := "00000000" & "00110---";
	constant OPCODE_LOADR :		T_OPCODE := "00000000" & "01------";
	constant OPCODE_STORER :	T_OPCODE := "00000000" & "10------";

	constant OPCODE_LED :		T_OPCODE := "00000000" & "1100000-";

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
		S_LED1,
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
		WRITE : out STD_LOGIC;
		LED : out STD_LOGIC
		);
end entity;

architecture behavioural of cpu is
	-- Shared
	signal LEFT, RIGHT : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');  -- inputs
	signal OPCODE : T_OPCODE := (others => '0');
	alias OP : T_ALU_OP is OPCODE (11 downto 8);
	alias LEFT_INDEX : T_REG_INDEX is OPCODE (5 downto 3);
	alias RIGHT_INDEX : T_REG_INDEX is OPCODE (2 downto 0);
	alias FLOWTYPE : T_FLOWTYPE is OPCODE (2 downto 1);
	alias FLOW_POLARITY : STD_LOGIC is OPCODE (0);
	signal STATE : T_STATE := S_FETCH1;

	-- ALU
	signal ALU_DO_OP : STD_LOGIC := '0';
	signal ALU_CARRY_IN : STD_LOGIC := '0';
	signal ALU_RESULT : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');  -- outputs
	signal ALU_CARRY_OUT : STD_LOGIC := '0';
	signal ALU_ZERO_OUT : STD_LOGIC := '0';
	signal ALU_NEG_OUT : STD_LOGIC := '0';

	-- Registers
	signal REGS_CLEAR : STD_LOGIC := '0';
	signal REGS_WRITE : STD_LOGIC := '0';
	signal REGS_WRITE_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_INPUT : T_REG  := (others => '0');

	-- PC
	signal PC_JUMP : STD_LOGIC := '0';
	signal PC_BRANCH : STD_LOGIC := '0';
	signal PC_INPUT : T_REG := (others => '0');
	signal PC_INCREMENT : STD_LOGIC := '0';
	signal PC_OUTPUT : T_REG := (others => '0');
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
		CLEAR => REGS_CLEAR,
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
		JUMP => PC_JUMP,
		BRANCH => PC_BRANCH,
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
			PC_JUMP <= '0';
			PC_BRANCH <= '0';
			PC_INCREMENT <= '0';
			REGS_CLEAR <= '0';
			REGS_WRITE <= '0';
			ALU_DO_OP <= '0';
			READ <= '0';
			WRITE <= '0';
			LED <= '0';
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

						when OPCODE_LED =>
							STATE <= S_LED1;

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
					REGS_WRITE_INDEX <= RIGHT_INDEX;
					REGS_WRITE <= '1';
					STATE <= S_FETCH1;

				when S_STOREI1 =>
					ADDRESS <= PC_OUTPUT;
					READ <= '1';
					PC_INCREMENT <= '1';
					STATE <= S_STOREI2;

				when S_STOREI2 =>
					ADDRESS <= DATA_IN;
					DATA_OUT <= STD_LOGIC_VECTOR(RIGHT);
					WRITE <= '1';
					STATE <= S_FETCH1;

				when S_CLEAR1 =>
					REGS_WRITE_INDEX <= RIGHT_INDEX;
					REGS_CLEAR <= '1';
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
--pragma synthesis_off
					report "CPU: STORER Address reg=" & to_hstring(LEFT_INDEX) & " (" & to_hstring(LEFT) & ") Data reg=" &
						to_hstring(RIGHT_INDEX) & " (" & to_hstring(RIGHT) & ")";
--pragma synthesis_on
						ADDRESS <= STD_LOGIC_VECTOR(LEFT);
					DATA_OUT <= STD_LOGIC_VECTOR(RIGHT);
					WRITE <= '1';
					STATE <= S_FETCH1;

				when S_LED1 =>
					LED <= OPCODE(0);
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
					report "CPU: ALU OP " & to_hstring(OP) & " Operand reg=" & to_hstring(LEFT_INDEX) &
						" (" & to_hstring(LEFT) & ") Dest reg=" & to_hstring(RIGHT_INDEX) &
						" (" & to_hstring(RIGHT) & ")" & " Result=" & to_hstring(ALU_RESULT);
--pragma synthesis_on
					REGS_INPUT <= T_REG(ALU_RESULT);
					REGS_WRITE_INDEX <= RIGHT_INDEX;
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
