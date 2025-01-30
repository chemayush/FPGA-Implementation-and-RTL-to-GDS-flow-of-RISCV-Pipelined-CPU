`timescale 1ns / 1ps


// pl_riscv_cpu.v - Top Module to test riscv_cpu

module pl_riscv_cpu (
    input         clk, reset,
    output        correct, 
    output [31:0] Instr
);

//wire [31:0] PC;
wire [31:0] PC, DataAdr_rv32, WriteData_rv32, Ext_WriteData, Ext_DataAdr, InstrD, WriteData, DataAdr, ReadData,
            PCW, Result, ALUResultW, ALUResultE, ALUResultM, WriteDataW, PCD, PCE, PCM, SrcAE, SrcBE, lAuiPCE, 
            lAuiPCW, ImmExtE ;
wire [ 2:0] Store, funct3;
wire [1:0]  ResultSrcE, ForwardAE, ForwardBE;
wire        MemWrite_rv32, Ext_MemWrite, MemWrite, luiE, unsign;
wire        PCSrc, RegWriteM, RegWriteW, StallF, StallD, FlushD, FlushE;
wire [3:0]  ALUControlE;
wire [ 4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

assign Ext_MemWrite = 1'b0;
assign Ext_WriteData = 32'h0;
assign Ext_DataAdr = 32'h0;

riscv_cpu rvcpu    (clk, reset, PC, Instr,
                    MemWrite_rv32, DataAdr_rv32,
                    WriteData_rv32, ReadData, Result,
                    funct3, PCW, ALUResultW, ALUResultE, ALUResultM, WriteDataW, InstrD, PCD, PCE, PCM, SrcAE, SrcBE, lAuiPCE, lAuiPCW, ImmExtE, luiE, ALUControlE,
						  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, PCSrc, RegWriteM, RegWriteW, StallF, StallD, FlushD, FlushE, ForwardAE, ForwardBE, ResultSrcE, unsign);
instr_mem instrmem (PC, Instr);
data_mem  datamem  (clk, reset, MemWrite, Store, DataAdr, WriteData, ReadData, correct);

assign Store = (Ext_MemWrite && reset) ? 3'b010 : funct3;
assign MemWrite  = (Ext_MemWrite && reset) ? 1'b1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule





