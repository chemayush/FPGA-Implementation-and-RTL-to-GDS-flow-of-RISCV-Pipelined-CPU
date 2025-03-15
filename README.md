# FPGA Implementation and RTL2GDS flow of Pipelined RISCV CPU

Project Video Demo: https://www.youtube.com/watch?v=TH6pEtpBv0k

# Overview
- This project implements a 5-stage pipelined RISC-V CPU in Verilog, synthesized and tested on the PYNQ Z2 FPGA board. The CPU executes a custom Path Planning Algorithm that computes optimal routes on a predefined map. The algorithm is compiled to machine code, loaded into the CPU's instruction memory, and validated using FPGA hardware feedback (GREEN LED).
- Further, the RISC-V CPU core has been fully implemented using the **OpenLane** automated ASIC flow, carrying out the Synthesis, Floorplanning and Placement, Clock Tree Synthesis, Routing, Static Timing Analysis, Power Analysis, GDSII generation.

### Technologies
- Xilinx Vivado is used for writing the RTL code, synthesis and implementation on the PYNQ Z2 FPGA. Behavioral simulation is also carried out.
- Openlane is used for the entire ASIC flow. Following tools are used inside of the flow:
  - ***Yosys*** is used for Synthesis.
  - ***OpenROAD*** handles the floorplanning and generates optimized clock tree.
  - ***TritonRoute*** performs the detailed routing of the design.
  - ***OpenSTA*** carries out the timing and power analysis.
  - ***Magic*** and ***KLayout*** is used for the DRC.

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
<p align="center">
  <img src="https://github.com/user-attachments/assets/d7910232-4146-4720-bf42-cedc7cdbb285">
</p>
<!-- ![image](https://github.com/user-attachments/assets/d7910232-4146-4720-bf42-cedc7cdbb285) -->

# Simulation and ILA
Simulation waveform shows the ***Instr*** values before and after the the ***correct*** signal goes high. We can verify its equality with the actual implementation's values visible in the ILA waveform.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d616c9d0-694b-43f0-9fda-25db49c76463" alt="Simulation waveform">
</p>
<p align="center"><strong>Figure 1:</strong> Simulation waveform.</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/9843c1bb-edde-4eca-b08b-2b9a05070e13" alt="ILA waveform">
</p>
<p align="center"><strong>Figure 2:</strong> ILA waveform.</p>
