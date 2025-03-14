# FPGA-Implementation-of-Pipelined-RISCV-Cpu

# Overview
- This project implements a 5-stage pipelined RISC-V CPU in Verilog, synthesized and tested on the PYNQ Z2 FPGA board. The CPU executes a custom Path Planning Algorithm that computes optimal routes on a predefined map. The algorithm is compiled to machine code, loaded into the CPU's instruction memory, and validated using FPGA hardware feedback (GREEN LED).
- Further, the RISC-V CPU core has been fully implemented using the **OpenLane** automated ASIC flow, carrying out the Synthesis, Floorplanning and Placement, Clock Tree Synthesis, Routing, Static Timing Analysis, Power Analysis, GDSII generation.

# Key Features
### RISC-V CPU Core

- 5-stage pipeline (IF, ID, EX, MEM, WB) with hazard detection and forwarding.

- Implements RV32I Base Integer Instruction Set.

- Synthesizable Verilog RTL design targeting the PYNQ Z2 FPGA.

### Path Planning Algorithm

- DFS based path planning algorithm a particular graph.

- Start/end points stored in data memory at predefined (defined in the C program) addresses.

- Computed path stored back to data memory for verification.

# Architecture 
the architecture has been referred from the Harris & Harris Book.

![image](https://github.com/user-attachments/assets/d7910232-4146-4720-bf42-cedc7cdbb285)
