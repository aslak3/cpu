library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;

entity alu_tb is
end entity;

architecture behavioral of alu_tb is
	signal CLOCK : STD_LOGIC;
	signal ALU_DO_OP : STD_LOGIC;
	signal ALU_OP : T_ALU_OP;
	signal ALU_LEFT, ALU_RIGHT : STD_LOGIC_VECTOR (15 downto 0);  -- inputs
	signal ALU_CARRY_IN : STD_LOGIC;
	signal ALU_RESULT : STD_LOGIC_VECTOR (15 downto 0);  -- outputs
	signal ALU_CARRY_OUT : STD_LOGIC;
	signal ALU_ZERO_OUT : STD_LOGIC;
	signal ALU_NEG_OUT : STD_LOGIC;

begin
	dut: entity work.alu port map (
		CLOCK => CLOCK,
		DO_OP => ALU_DO_OP,
		OP => ALU_OP,
		LEFT => ALU_LEFT,
		RIGHT => ALU_RIGHT,
		CARRY_IN => ALU_CARRY_IN,
		RESULT => ALU_RESULT,
		CARRY_OUT => ALU_CARRY_OUT,
		ZERO_OUT => ALU_ZERO_OUT,
		NEG_OUT => ALU_NEG_OUT
	);

	process
		procedure run_test (
			OP : T_ALU_OP;
			LEFT : STD_LOGIC_VECTOR (15 downto 0);
			RIGHT : STD_LOGIC_VECTOR (15 downto 0);
			CARRY_IN : STD_LOGIC;
			EXP_RESULT : STD_LOGIC_VECTOR (15 downto 0);
			EXP_CARRY : STD_LOGIC;
			EXP_ZERO : STD_LOGIC;
			EXP_NEG : STD_LOGIC
			) is
		begin
			report "Op=" & to_string(OP) & " Left=" & to_hstring(LEFT) &
				" Right=" & to_hstring(RIGHT) & " Carry=" & to_string(CARRY_IN);

			CLOCK <= '0';
			ALU_DO_OP <= '0';
			ALU_OP <= OP;
			ALU_LEFT <= LEFT;
			ALU_RIGHT <= RIGHT;
			ALU_CARRY_IN <= CARRY_IN;

			wait for 1 ns;
			CLOCK <= '1';
			ALU_DO_OP <= '1';
			wait for 1 ns;

			report "Result=" & to_hstring(ALU_RESULT);
			report "Carry=" & to_string(ALU_CARRY_OUT) & " Zero=" & to_string(ALU_ZERO_OUT) &
				" Neg=" & to_string(ALU_NEG_OUT);

			assert ALU_RESULT = EXP_RESULT
				report "Result got " & to_hstring(ALU_RESULT) & " expected " & to_hstring(EXP_RESULT) severity failure;
			assert ALU_CARRY_OUT = EXP_CARRY
				report "Carry got " & to_string(ALU_CARRY_OUT) & " expected " & to_string(EXP_CARRY) severity failure;
			assert ALU_ZERO_OUT = EXP_ZERO
				report "Zero got " & to_string(ALU_ZERO_OUT) & " expected " & to_string(EXP_ZERO) severity failure;
			assert ALU_NEG_OUT = EXP_NEG
				report "Negative got  " & to_string(ALU_NEG_OUT) & " expected " & to_string(EXP_NEG) severity failure;

		end procedure;
	begin
		-- One destination, one operand
		run_test(OP_ADD,	x"0001", x"0002" ,'0',	x"0003", '0', '0', '0');
		run_test(OP_ADDC,	x"0001", x"0002" ,'0',	x"0003", '0', '0', '0');
		run_test(OP_ADDC,	x"0001", x"0002" ,'1',	x"0004", '0', '0', '0');
		run_test(OP_ADD,	x"ffff", x"0001" ,'0',	x"0000", '1', '1', '0');
		run_test(OP_ADDC,	x"ffff", x"0000" ,'1',	x"0000", '1', '1', '0');
		run_test(OP_ADDC,	x"8000", x"7fff" ,'0',	x"ffff", '0', '0', '1');
		run_test(OP_ADDC,	x"8000", x"7fff" ,'0',	x"ffff", '0', '0', '1');

		run_test(OP_SUB,	x"0002", x"0001" ,'0',	x"ffff", '1', '0', '1');
		run_test(OP_SUBC,	x"0002", x"0001" ,'0',	x"ffff", '1', '0', '1');
		run_test(OP_SUBC,	x"0002", x"0001" ,'1',	x"fffe", '1', '0', '1');
		run_test(OP_SUB,	x"0001", x"ffff" ,'0',	x"fffe", '0', '0', '1');
		run_test(OP_SUBC,	x"0000", x"ffff" ,'1',	x"fffe", '0', '0', '1');
		run_test(OP_SUBC,	x"ffff", x"ffff" ,'1',	x"ffff", '1', '0', '1');
		run_test(OP_SUBC,	x"ffff", x"ffff" ,'0',	x"0000", '0', '1', '0');

		run_test(OP_AND,	x"8080", x"ff00", '0',	x"8000", '0', '0', '1');
		run_test(OP_AND,	x"0880", x"ff00", '0',	x"0800", '0', '0', '0');
		run_test(OP_AND,	x"8080", x"0808", '0',	x"0000", '0', '1', '0');

		run_test(OP_OR,		x"8080", x"ff00", '0',	x"ff80", '0', '0', '1');
		run_test(OP_OR,		x"0880", x"ff00", '0',	x"ff80", '0', '0', '1');
		run_test(OP_OR,		x"8080", x"0808", '0',	x"8888", '0', '0', '1');
		run_test(OP_OR,		x"0000", x"0000", '0',	x"0000", '0', '1', '0');
		run_test(OP_OR,		x"1000", x"0001", '0',	x"1001", '0', '0', '0');

		run_test(OP_XOR,	x"8080", x"ff00", '0',	x"7f80", '0', '0', '0');
		run_test(OP_XOR,	x"0880", x"ff00", '0',	x"f780", '0', '0', '1');
		run_test(OP_XOR,	x"8080", x"0808", '0',	x"8888", '0', '0', '1');
		run_test(OP_XOR,	x"0000", x"0000", '0',	x"0000", '0', '1', '0');
		run_test(OP_XOR,	x"1000", x"0001", '0',	x"1001", '0', '0', '0');

		run_test(OP_COPY,	x"f0f0", x"0000", '0',	x"f0f0", '0', '0', '1');
		run_test(OP_COPY,	x"0000", x"0000", '0',	x"0000", '0', '1', '0');
		run_test(OP_COPY,	x"0000", x"0000", '0',	x"0000", '0', '1', '0');

		run_test(OP_COMP,	x"0001", x"0002", '0', x"0002", '0', '0', '0');
		run_test(OP_COMP,	x"0002", x"0001", '0', x"0001", '1', '0', '1');
		run_test(OP_COMP,	x"0001", x"0001", '0', x"0001", '0', '1', '0');
		run_test(OP_COMP,	x"0000", x"8000", '0', x"8000", '0', '0', '1');

		run_test(OP_BIT,	x"8080", x"ff00", '0',	x"ff00", '0', '0', '1');
		run_test(OP_BIT,	x"0880", x"ff00", '0',	x"ff00", '0', '0', '0');
		run_test(OP_BIT,	x"8080", x"0808", '0',	x"0808", '0', '1', '0');

		-- No operand
		run_test(OP_INC,	x"0000", x"0000" ,'0',	x"0001", '0', '0', '0');
		run_test(OP_INC,	x"0000", x"7fff" ,'0',	x"8000", '0', '0', '1');
		run_test(OP_INC,	x"0000", x"ffff" ,'0',	x"0000", '1', '1', '0');

		run_test(OP_DEC,	x"0000", x"0000" ,'0',	x"ffff", '1', '0', '1');
		run_test(OP_DEC,	x"0000", x"0001" ,'0',	x"0000", '0', '1', '0');
		run_test(OP_DEC,	x"0000", x"ffff" ,'0',	x"fffe", '0', '0', '1');

		run_test(OP_INCD,	x"0000", x"ffff" ,'0',	x"0001", '1', '0', '0');
		run_test(OP_INCD,	x"0000", x"7ffe" ,'0',	x"8000", '0', '0', '1');
		run_test(OP_INCD,	x"0000", x"fffe" ,'0',	x"0000", '1', '1', '0');

		run_test(OP_DECD,	x"0000", x"0001" ,'0',	x"ffff", '1', '0', '1');
		run_test(OP_DECD,	x"0000", x"0002" ,'0',	x"0000", '0', '1', '0');
		run_test(OP_DECD,	x"0000", x"0000" ,'0',	x"fffe", '1', '0', '1');

		run_test(OP_NOT,	x"0000", x"8080", '0',	x"7f7f", '0', '0', '0');
		run_test(OP_NOT,	x"0000", x"ffff", '0',	x"0000", '0', '1', '0');
		run_test(OP_NOT,	x"0000", x"0000", '0',	x"ffff", '0', '0', '1');

		run_test(OP_LEFT,	x"0000", x"8080", '0',	x"0100", '1', '0', '0');
		run_test(OP_LEFT,	x"0000", x"ffff", '0',	x"fffe", '1', '0', '1');
		run_test(OP_LEFT,	x"0000", x"0000", '0',	x"0000", '0', '1', '0');
		run_test(OP_LEFT,	x"0000", x"0001", '0',	x"0002", '0', '0', '0');

		run_test(OP_RIGHT,	x"0000", x"8080", '0',	x"4040", '0', '0', '0');
		run_test(OP_RIGHT,	x"0000", x"ffff", '0',	x"7fff", '1', '0', '0');
		run_test(OP_RIGHT,	x"0000", x"0000", '0',	x"0000", '0', '1', '0');

		run_test(OP_NEG,	x"0000", x"0001", '0', x"ffff", '1', '0', '1');
		run_test(OP_NEG,	x"0000", x"ffff", '0', x"0001", '1', '0', '0');
		run_test(OP_NEG,	x"0000", x"0000", '0', x"0000", '0', '1', '0');

		run_test(OP_TEST,	x"0000", x"0001", '0', x"0001", '0', '0', '0');
		run_test(OP_TEST,	x"0000", x"ffff", '0', x"ffff", '0', '0', '1');
		run_test(OP_TEST,	x"0000", x"0000", '0', x"0000", '0', '1', '0');

		report "+++All good";
		std.env.finish;
	end process;

end architecture;
