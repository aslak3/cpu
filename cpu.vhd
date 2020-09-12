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
		ADDRESS : out STD_LOGIC_VECTOR (14 downto 0);
		UPPER_DATA : out STD_LOGIC;
		LOWER_DATA : out STD_LOGIC;
		DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
		DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
		BUS_ERROR : out STD_LOGIC;
		READ : out STD_LOGIC;
		WRITE : out STD_LOGIC
	);
end entity;

architecture behavioural of cpu is
	signal ALU_LEFT_MUX_SEL : T_ALU_LEFT_MUX_SEL;
	signal ALU_RIGHT_MUX_SEL : T_ALU_RIGHT_MUX_SEL;
	signal REGS_INPUT_MUX_SEL : T_REGS_INPUT_MUX_SEL;
	signal ADDRESS_MUX_SEL : T_ADDRESS_MUX_SEL;
	signal DATA_OUT_MUX_SEL : T_DATA_OUT_MUX_SEL;

	signal CYCLE_TYPE : T_CYCLE_TYPE;
	signal CPU_DATA_IN_EXTENDED : T_REG := (others => '0');

	-- CPU
	signal CPU_ADDRESS : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal CPU_DATA_IN : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal CPU_DATA_OUT : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal CPU_CYCLE_TYPE_BYTE : STD_LOGIC := '0';

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
	signal REGS_INC : STD_LOGIC := '0';
	signal REGS_DEC : STD_LOGIC := '0';
	signal REGS_LEFT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_RIGHT_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_WRITE_INDEX : T_REG_INDEX := (others => '0');
	signal REGS_LEFT_OUTPUT : T_REG := (others => '0');
	signal REGS_RIGHT_OUTPUT : T_REG := (others => '0');
	signal REGS_INPUT : T_REG  := (others => '0');

	-- PC
	signal PC_JUMP : STD_LOGIC := '0';
	signal PC_BRANCH : STD_LOGIC := '0';
	signal PC_INCREMENT : STD_LOGIC := '0';
	signal PC_OUTPUT : T_REG := (others => '0');

	-- Temporary
	signal TEMPORARY_WRITE : STD_LOGIC := '0';
	signal TEMPORARY_OUTPUT : T_REG := (others => '0');

begin
	control: entity work.control port map (
		CLOCK => CLOCK,
		RESET => RESET,
		DATA_IN => DATA_IN,
		READ => READ,
		WRITE => WRITE,
		CYCLE_TYPE => CYCLE_TYPE,

		ALU_LEFT_MUX_SEL => ALU_LEFT_MUX_SEL,
		ALU_RIGHT_MUX_SEL => ALU_RIGHT_MUX_SEL,
		REGS_INPUT_MUX_SEL => REGS_INPUT_MUX_SEL,
		ADDRESS_MUX_SEL => ADDRESS_MUX_SEL,
		DATA_OUT_MUX_SEL => DATA_OUT_MUX_SEL,

		ALU_DO_OP => ALU_DO_OP,
		ALU_OP => ALU_OP,
		ALU_CARRY_IN => ALU_CARRY_IN,
		ALU_CARRY_OUT => ALU_CARRY_OUT,
		ALU_ZERO_OUT => ALU_ZERO_OUT,
		ALU_NEG_OUT => ALU_NEG_OUT,

		REGS_CLEAR => REGS_CLEAR,
		REGS_WRITE => REGS_WRITE,
		REGS_INC => REGS_INC,
		REGS_DEC => REGS_DEC,
		REGS_LEFT_INDEX => REGS_LEFT_INDEX,
		REGS_RIGHT_INDEX => REGS_RIGHT_INDEX,

		PC_JUMP => PC_JUMP,
		PC_BRANCH => PC_BRANCH,
		PC_INCREMENT => PC_INCREMENT,

		TEMPORARY_WRITE => TEMPORARY_WRITE,
		TEMPORARY_OUTPUT => TEMPORARY_OUTPUT
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
		INC => REGS_INC,
		DEC => REGS_DEC,
		READ_LEFT_INDEX => REGS_LEFT_INDEX,
		READ_RIGHT_INDEX => REGS_RIGHT_INDEX,
		WRITE_INDEX => REGS_RIGHT_INDEX,
		INCDEC_INDEX => REGS_LEFT_INDEX,
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

	temporary: entity work.temporary port map (
		CLOCK => CLOCK,
		RESET => RESET,
		WRITE => TEMPORARY_WRITE,
		INPUT => DATA_IN,
		OUTPUT => TEMPORARY_OUTPUT
	);

	businterface: entity work.businterface port map (
		CPU_ADDRESS => CPU_ADDRESS,
		CPU_CYCLE_TYPE_BYTE => CPU_CYCLE_TYPE_BYTE,
		CPU_DATA_OUT => CPU_DATA_OUT,
		CPU_DATA_IN => CPU_DATA_IN,

		BUSINTERFACE_ADDRESS => ADDRESS,
		BUSINTERFACE_DATA_IN => DATA_IN,
		BUSINTERFACE_DATA_OUT => DATA_OUT,
		BUSINTERFACE_UPPER_DATA => UPPER_DATA,
		BUSINTERFACE_LOWER_DATA => LOWER_DATA,
		BUSINTERFACE_ERROR => BUS_ERROR,

		READ => READ,
		WRITE => WRITE
	);

	-- Sign extend for data into a register, ie. LOADR, LOADRD
	CPU_DATA_IN_EXTENDED <=
		(8 to 15 => CPU_DATA_IN (7)) & CPU_DATA_IN (7 downto 0) when
		(CYCLE_TYPE = CYCLE_TYPE_BYTE_SIGNED) else
		(8 to 15 => '0') & CPU_DATA_IN (7 downto 0) when
		(CYCLE_TYPE = CYCLE_TYPE_BYTE_UNSIGNED) else
		CPU_DATA_IN;

	ALU_LEFT_IN <= 	REGS_LEFT_OUTPUT when (ALU_LEFT_MUX_SEL = S_REGS_LEFT) else
					CPU_DATA_IN;
	ALU_RIGHT_IN <=	REGS_RIGHT_OUTPUT when (ALU_RIGHT_MUX_SEL = S_REGS_RIGHT) else
					CPU_DATA_IN;
	REGS_INPUT <= 	ALU_RESULT when (REGS_INPUT_MUX_SEL = S_ALU_RESULT) else
					REGS_RIGHT_OUTPUT when (REGS_INPUT_MUX_SEL = S_REGS_RIGHT) else
					TEMPORARY_OUTPUT when (REGS_INPUT_MUX_SEL = S_TEMPORARY_OUTPUT) else
					CPU_DATA_IN_EXTENDED;
	CPU_ADDRESS <=	PC_OUTPUT when (ADDRESS_MUX_SEL = S_PC) else
					REGS_LEFT_OUTPUT when (ADDRESS_MUX_SEL = S_REGS_LEFT) else
					REGS_RIGHT_OUTPUT when (ADDRESS_MUX_SEL = S_REGS_RIGHT) else
					ALU_RESULT when (ADDRESS_MUX_SEL = S_ALU_RESULT) else
					TEMPORARY_OUTPUT when (ADDRESS_MUX_SEL = S_TEMPORARY_OUTPUT) else
					CPU_DATA_IN;
	CPU_DATA_OUT <=	PC_OUTPUT when (DATA_OUT_MUX_SEL = S_PC) else
					REGS_LEFT_OUTPUT when (DATA_OUT_MUX_SEL = S_REGS_LEFT) else
					REGS_RIGHT_OUTPUT;

	-- Set the byte cycle state, if we are doing one.
	CPU_CYCLE_TYPE_BYTE <= '1' when (
		(CYCLE_TYPE = CYCLE_TYPE_BYTE_SIGNED or CYCLE_TYPE = CYCLE_TYPE_BYTE_UNSIGNED)
	) else '0';

end architecture;
