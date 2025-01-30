# FPGA-Implementation-of-Pipelined-RISCV-Cpu

1) I have implemented a 5-Stage Pipelined RISCV CPU (Verilog) on PYNQ Z2 FPGA Board.
2) I have also written a Path Planning Algorithm for a custom map. It is then converted to a Hex file, which is dumped into the Instruction Memory.
3) I have already stored the "Start Point" and "End Point" in the Data Memory at certain memory locations (as specified in path_planner.c).
4) These memory locations are accessed by the program. It then calulates the path and stores them in certain memory locations (as specified in path_planner.c)
5) If the path calcualted by the program is correct, then the "correct" signal in top module becomes HIGH. "correct" signal is a combinational logic, that checks if the path is correct through the Data Memory.
6) The "correct" signal is connected to the GREEN LED on the PYNQ Z2 board. Hence, if the path is correct, GREEN LED lights up.
7) This works for any valid path on the map.
