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

- **DFS-based Path Planning Algorithm** applied on a particular graph (defined in the [Path Planner C program](https://github.com/chemayush/FPGA-Implementation-and-RTL-to-GDS-of-RISCV-Pipelined-CPU/blob/main/path_planner/path_planner.c)).

- Start/end points stored in data memory at predefined (defined in the [Path Planner C program](https://github.com/chemayush/FPGA-Implementation-and-RTL-to-GDS-of-RISCV-Pipelined-CPU/blob/main/path_planner/path_planner.c)) addresses.

- Computed path stored back to data memory for verification.

# Architecture 
the architecture has been referred from the Harris & Harris Book.
<p align="center">
  <img src="https://github.com/user-attachments/assets/d7910232-4146-4720-bf42-cedc7cdbb285">
</p>
<p align="center"><strong>Figure 1:</strong> Pipelined RV32I Architecture</p>
<!-- ![image](https://github.com/user-attachments/assets/d7910232-4146-4720-bf42-cedc7cdbb285) -->

# Simulation and ILA
Simulation waveform shows the ***Instr*** values before and after the the ***correct*** signal goes high. We can verify its equality with the actual implementation's values visible in the ILA waveform.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d616c9d0-694b-43f0-9fda-25db49c76463" alt="Simulation waveform">
</p>
<p align="center"><strong>Figure 2:</strong> Simulation waveform.</p>


<p align="center">
  <img src="https://github.com/user-attachments/assets/9843c1bb-edde-4eca-b08b-2b9a05070e13" alt="ILA waveform">
</p>
<p align="center"><strong>Figure 3:</strong> ILA waveform.</p>

# GDSII Flow
OpenLane is an Open Source toolchain which combines multiple tools to automate the RTL to GDSII flow. Below are analysis of different metrics at various stages.

## 1. Synthesis 

| **Category**         | **Count** | **Cell Type**               | **Count** | **Cell Type**               | **Count** |
|----------------------|-----------|-----------------------------|-----------|-----------------------------|-----------|
| Wires                | 16895     | `$_ANDNOT_`                 | 1340      | `$_MUX_`                   | 11104     |
| Wire bits            | 20807     | `$_AND_`                    | 91        | `$_NAND_`                  | 66        |
| Public wires         | 163       | `$_NOR_`                    | 244       | `$_NOT_`                   | 2757      |
| Public wire bits     | 3979      | `$_ORNOT_`                  | 108       | `$_OR_`                    | 1050      |
| Memories             | 0         | `$_XNOR_`                   | 54        | `$_XOR_`                   | 167       |
| Memory bits          | 0         | `sky130_fd_sc_hd__dfxtp_2`  | 3663      | `sky130_fd_sc_hd__dlxtn_1` | 37        |
| Processes            | 0         |                             |           |                             |           |
| Cells                | 20681     |                             |           |                             |           |



## 2. Timing Analysis

| **Metric**               | **Post-Synthesis STA**   | **Post-PnR STA**   | **Final (Post Opt.) STA**  | **Notes**                                                                 |
|--------------------------|--------------------------|--------------------|----------------------------|---------------------------------------------------------------------------|
| **Worst Slack (Setup)**  | `9.35 ns`                | `8.88 ns`          | **`9.27 ns`**              | Positive slack = timing met. Final slack reflects post-optimization.      |
| **Worst Slack (Hold)**   | `0.08 ns`                | `0.18 ns`          | **`0.35 ns`**              | Robust hold margin achieved in final design.                              |
| **TNS (Total Neg Slack)**| `0.00 ns`                | `0.00 ns`          | `0.00 ns`                  | No cumulative timing violations.                                          |
| **WNS (Worst Neg Slack)**| `0.00 ns`                | `0.00 ns`          | `0.00 ns`                  | All paths meet timing constraints.                                        |  

**Final Performance**:  
- **Minimum Clock Period**: `11.84 ns`  
- **Maximum Clock Frequency**: **`84.45 MHz`** (achieved operational frequency).  

<p align="center">
  <img src="https://github.com/user-attachments/assets/2c26c152-04d4-4f71-92aa-8898066c4b86">
</p>
<p align="center"><strong>Figure 4:</strong> Timing Report </p>


## 3. Power Analysis



| Group           | Internal Power (W) | Switching Power (W) | Leakage Power (W) | Total Power (W) | Percentage |
|-----------------|--------------------|---------------------|-------------------|-----------------|------------|
| **Sequential**  | 7.35e-03           | 1.13e-03            | 3.01e-08          | 8.48e-03        | 22.0%      |
| **Combinational**| 8.06e-03          | 1.32e-02            | 7.95e-08          | 2.12e-02        | 55.1%      |
| **Clock**       | 4.61e-03           | 4.19e-03            | 4.03e-08          | 8.80e-03        | 22.9%      |
| **Macro**       | 0.00e+00           | 0.00e+00            | 0.00e+00          | 0.00e+00        | 0.0%       |
| **Pad**         | 0.00e+00           | 0.00e+00            | 0.00e+00          | 0.00e+00        | 0.0%       |
| **Total**       | **2.00e-02**       | **1.85e-02**        | **1.50e-07**      | **3.85e-02**    | **100.0%** |

<p align="center">
  <img src="https://github.com/user-attachments/assets/8a7ec5fb-1407-4e0d-8e1a-9f13e7ba51f0">
</p>
<p align="center"><strong>Figure 5:</strong> Power Density Heat Map</p>
<!-- ![image](https://github.com/user-attachments/assets/8a7ec5fb-1407-4e0d-8e1a-9f13e7ba51f0) -->


<p align="center">
  <img src="https://github.com/user-attachments/assets/4e40206f-547f-4aab-8069-4b07c51c2e92">
</p>
<p align="center"><strong>Figure 6:</strong> Placement Density Heat Map</p>


<p align="center">
  <img src="https://github.com/user-attachments/assets/2ae5c83d-9eae-4046-901a-5da1075925a9">
</p>
<p align="center"><strong>Figure 6:</strong> Routing Congestion Heat Map</p>
<!-- ![image](https://github.com/user-attachments/assets/2ae5c83d-9eae-4046-901a-5da1075925a9) -->

## 4. Other Metrics

| **Metric**                | **Value**           | **Description**                                                                 |
|---------------------------|---------------------|---------------------------------------------------------------------------------|
| Cell Library              | `sky130_fd_sc_hd`   | Standard cell library used.                                                     |
| Floorplan Dimensions      | `626.98 μm × 625.6 μm` | Width × Height of the floorplan.                                               |
| Core Area                 | `0.3922 mm²`        | Available area for logic/macros within the die.                                 |
| Design Area               | `0.2565 mm²`        | Actual area occupied by placed cells.                                           |
| DIE Area                  | `0.4143 mm²`        | Total chip area (including I/Os and periphery).                                 |
| Core Utilization          | **65.4%**           | (Design Area / Core Area) × 100.                                                |
| Cell Density              | `110,393 cells/mm²` | Cells per mm² of the utilized core area                                        |

| **Metric**                | **Value**           | **Description**                                                                 |
|---------------------------|---------------------|---------------------------------------------------------------------------------|
| Supply Voltage (VDD)      | `1.8 V`             | Nominal operating voltage.                                                      |
| Average IR Drop (VDD)     | `0.294 mV`          | Average voltage drop across the power network.                                  |
| Worst-Case IR Drop (VDD)  | `1.36 mV`           | Maximum localized voltage drop (critical path).                                 |
| VDD % Drop                | `0.08%`             | (Worst-Case IR Drop / Supply Voltage) × 100.                                    |
| Worst Ground Bounce (VSS) | `1.55 mV`           | Maximum voltage rise on ground network.                                         |
| Average Ground Bounce     | `0.291 mV`          | Average voltage deviation from ideal ground (0 V).                              |
| VSS % Deviation           | `0.09%`             | (Worst Ground Bounce / Supply Voltage) × 100.                                   |

#### Takeaways:
- IR drop is exceptionally low (`< 0.1%` of supply voltage), indicating a well-designed power distribution network (PDN).  
- **65.4% core utilization** leaves adequate space (`34.6%`) for routing and timing optimization.  
- High cell density (`110k cells/mm²`) reflects efficient area usage typical for the sky130 node.

  
