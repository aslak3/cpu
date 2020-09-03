library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_REGS.all;
use work.P_CONTROL.all;

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
	signal ALU_LEFT_MUX_SEL : T_ALU_LEFT_MUX_SEL;
	signal ALU_RIGHT_MUX_SEL : T_ALU_RIGHT_MUX_SEL;
	signal REGS_INPUT_MUX_SEL : T_REGS_INPUT_MUX_SEL;
	signal ADDRESS_MUX_SEL : T_ADDRESS_MUX_SEL;

	-- ALU
	signal ALU_DO_OP : STD_LOGIC := '0';
	signal ALU_OP : T_ALU_OP := (others => '0');
	signal ALU_LEFT_IN : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal ALU_RIGHT_IN : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal ALU_CARRY_IN : STD_LOGIC := '0';
	signal ALU_RESULT : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');  -- outputs
	signal ALU_CARRY_OUT : STD_LOGIC := '0';
	signal ALU_ZERO_OUT : STD_LOGIC := '0';
	signal ALU_NEG_OUT : STD_LOGIC := '0';

	-- Registers
	signal REGS_CLEAR : STD_LOGIC := '0';
	signal REGS_WRITE : STD_LOGIC := '0';
	signal REGS_WRITE_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_LEFT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_RIGHT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_LEFT_OUTPUT : T_REG := (others => '0');
	signal REGS_RIGHT_OUTPUT : T_REG := (others => '0');
	signal REGS_INPUT : T_REG  := (others => '0');

	-- PC
	signal PC_JUMP : STD_LOGIC := '0';
	signal PC_BRANCH : STD_LOGIC := '0';
	signal PC_INCREMENT : STD_LOGIC := '0';
	signal PC_OUTPUT : T_REG := (others => '0');

begin
	control: entity work.control port map (
		CLOCK => CLOCK,
		RESET => RESET,
		DATA_IN => DATA_IN,
		READ => READ,
		WRITE => WRITE,

		ALU_LEFT_MUX_SEL => ALU_LEFT_MUX_SEL,
		ALU_RIGHT_MUX_SEL => ALU_RIGHT_MUX_SEL,
		REGS_INPUT_MUX_SEL => REGS_INPUT_MUX_SEL,
		ADDRESS_MUX_SEL => ADDRESS_MUX_SEL,

		ALU_DO_OP => ALU_DO_OP,
		ALU_OP => ALU_OP,
		ALU_CARRY_IN => ALU_CARRY_IN,
		ALU_CARRY_OUT => ALU_CARRY_OUT,
		ALU_ZERO_OUT => ALU_ZERO_OUT,
		ALU_NEG_OUT => ALU_NEG_OUT,

		REGS_CLEAR => REGS_CLEAR,
		REGS_WRITE => REGS_WRITE,
		REGS_WRITE_INDEX => REGS_WRITE_INDEX,
		REGS_LEFT_INDEX => REGS_LEFT_INDEX,
		REGS_RIGHT_INDEX => REGS_RIGHT_INDEX,

		PC_JUMP => PC_JUMP,
		PC_BRANCH => PC_BRANCH,
		PC_INCREMENT => PC_INCREMENT
	);

	alu: entity work.alu port map (
		CLOCK => CLOCK,
		DO_OP => ALU_DO_OP,
		OP => ALU_OP,
		LEFT => ALU_LEFT_IN,
		RIGHT => ALU_RIGHT_IN,
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
		READ_LEFT_INDEX => REGS_LEFT_INDEX,
		READ_RIGHT_INDEX => REGS_RIGHT_INDEX,
		WRITE_INDEX => REGS_WRITE_INDEX,
		LEFT_OUTPUT => REGS_LEFT_OUTPUT,
		RIGHT_OUTPUT => REGS_RIGHT_OUTPUT,
		INPUT => REGS_INPUT
	);

	programcounter: entity work.programcounter port map (
		CLOCK => CLOCK,
		RESET => RESET,
		JUMP => PC_JUMP,
		BRANCH => PC_BRANCH,
		INPUT => DATA_IN,
		INCREMENT => PC_INCREMENT,
		OUTPUT => PC_OUTPUT
	);

	ALU_LEFT_IN <= 	REGS_LEFT_OUTPUT when (ALU_LEFT_MUX_SEL = S_REGS_LEFT) else
					DATA_IN;
	ALU_RIGHT_IN <=	REGS_RIGHT_OUTPUT when (ALU_RIGHT_MUX_SEL = S_REGS_RIGHT) else
					DATA_IN;
	REGS_INPUT <= 	ALU_RESULT when (REGS_INPUT_MUX_SEL = S_ALU_RESULT) else
					REGS_RIGHT_OUTPUT when (REGS_INPUT_MUX_SEL = S_REGS_RIGHT) else
					DATA_IN;
	ADDRESS <=		PC_OUTPUT when (ADDRESS_MUX_SEL = S_PC) else
					REGS_LEFT_OUTPUT when (ADDRESS_MUX_SEL = S_REGS_LEFT) else
					ALU_RESULT when (ADDRESS_MUX_SEL = S_ALU_RESULT) else
					DATA_IN;

	DATA_OUT <=		REGS_RIGHT_OUTPUT;

end architecture;
