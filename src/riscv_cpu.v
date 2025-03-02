
// riscv_cpu.v - Pipelined RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWriteM,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [ 2:0] funct3,
    output [31:0] PCW, ALUResultW, ALUResultE, ALUResultM, WriteDataW, 
						InstrD, PCD, PCE, PCM, SrcAE, SrcBE, lAuiPCE, lAuiPCW, ImmExtE, 
	 output		   luiE,
	 output [ 3:0] ALUControlE,
	 output [ 4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, 
	 output        PCSrc, RegWriteM, RegWriteW, StallF, StallD, FlushD, FlushE, 
	 output [ 1:0] ForwardAE, ForwardBE,
	 output [ 1:0] ResultSrcE,
	 output unsign
);

wire        ALUSrc, RegWrite, Branch, Jump, Jalr, lui;
wire [1:0]  ResultSrc;
wire [2:0]  ImmSrc, funct3M;
wire [3:0]  ALUControl;
//wire [31:0] InstrD;

controller  c   (InstrD[6:0], InstrD[14:12], InstrD[30],
                ResultSrc, MemWrite, ALUSrc,
                RegWrite, Branch, Jump, Jalr, lui, ImmSrc, ALUControl, unsign);

datapath    dp  (clk, reset, ResultSrc, MemWrite,
                ALUSrc, RegWrite, ImmSrc, ALUControl, Branch, Jump, Jalr, lui, unsign,
                PC, Instr, Mem_WrAddr, Mem_WrData, ReadData, Result, PCW, ALUResultW, ALUResultE, ALUResultM, 
					 WriteDataW, InstrD, PCD, PCE, PCM, SrcAE, SrcBE, lAuiPCE, lAuiPCW, ImmExtE, luiE, MemWriteM, ALUControlE,
					 Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, PCSrc, RegWriteM, RegWriteW, StallF, StallD, FlushD, FlushE, 
					 ForwardAE, ForwardBE, ResultSrcE, funct3M);

assign funct3 = funct3M;

endmodule



