registers:
	vcom registers.vhd tb/registers_tb.vhd
alu:
	vcom alu.vhd tb/alu_tb.vhd
cpu:
	vcom cpu.vhd tb/cpu_tb.vhd

tests: registers_test alu_tests programcounter_tests cpu_tests

alu_tests:
	vsim -c alu_tb < sim-script
registers_tests:
	vsim -c registers_tb < sim-script
programcounter_tests:
	vsim -c programcounter_tb < sim-script
cpu_tests:
	vsim -c cpu_tb < sim-script
