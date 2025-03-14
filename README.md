# FPGA-Implementation-of-Pipelined-RISCV-Cpu

# Overview
This project implements a 5-stage pipelined RISC-V CPU in Verilog, synthesized and tested on the PYNQ Z2 FPGA board. The CPU executes a custom Path Planning Algorithm that computes optimal routes on a predefined map. The algorithm is compiled to machine code, loaded into the CPU's instruction memory, and validated using FPGA hardware feedback (GREEN LED). This demonstrates a full-stack integration of hardware design, computer architecture, and algorithm deployment.

# Key Features
RISC-V CPU Core

5-stage pipeline (IF, ID, EX, MEM, WB) with hazard detection and forwarding.

Implements RV32I Base Integer Instruction Set.

Synthesizable Verilog RTL design targeting the PYNQ Z2 FPGA.

Path Planning Algorithm

Customizable grid-based pathfinding algorithm (e.g., A*, BFS, or DFS).

Start/end points stored in data memory at predefined addresses.

Computed path stored back to data memory for verification.
