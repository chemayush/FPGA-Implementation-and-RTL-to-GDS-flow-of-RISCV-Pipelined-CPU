
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrcD, 
	 input 			MemWriteD,
    input         ALUSrcD, RegWriteD,
    input [2:0]   ImmSrcD,
    input [3:0]   ALUControlD,
    input         BranchD, JumpD, JalrD, luiD, unsignD,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadDataM,
    output [31:0] Result,
    output [31:0] PCW, ALUResultW, ALUResultE, ALUResultM, WriteDataW, InstrD, PCD, PCE, PCM, SrcAE, SrcBE, lAuiPCE, lAuiPCW, ImmExtE,
	 output        luiE, MemWriteM,
	 output [ 3:0] ALUControlE,
	 output [ 4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, 
	 output        PCSrc, RegWriteM, RegWriteW, StallF, StallD, FlushD, FlushE, 
	 output [ 1:0] ForwardAE, ForwardBE,
	 output [ 1:0] ResultSrcE,
	 output [ 2:0] funct3M
);

//wire StallF = 0;
//wire StallD = 0;
//wire FlushD = 0;
//wire FlushE = 0;
//wire StallF, StallD, FlushD, FlushE;
wire [ 2:0] funct3D, funct3E;
wire [31:0] PCPlus4, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W;
wire [31:0] PCNext, PCJalr, PCTarget, AuiPCE, lAuiPCM, RD1D, RD1E, RD2D, RD2E, ReadDataW, WriteDataM;
wire [31:0] ImmExtD, WriteDataE;
//wire [4:0] RdW, RdE, RdM, Rs1D, Rs1E, Rs2D, Rs2E;
//wire [3:0] ALUControlE;
wire [1:0] ResultSrcM, ResultSrcW;
wire RegWriteE, Zero, TakeBranch, Cout, BranchE, JumpE, JalrE, unsignE;
wire [4:0] RdD;

assign PCSrc = ((BranchE & TakeBranch) || JumpE || JalrE) ? 1'b1 : 1'b0;
assign Rs1D = InstrD[19:15];
assign Rs2D = InstrD[24:20];
assign RdD  = InstrD[11: 7];
assign funct3D = InstrD[14:12];

// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
mux2 #(32)     jalrmux (PCNext, ALUResultE, JalrE, PCJalr);

// stallF - should be wired from hazard unit
//wire StallF = 0; // remove it after adding hazard unit.
reset_ff #(32) pcreg(clk, reset, StallF, PCJalr, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);

// Pipeline Register 1 -> Fetch | Decode
//wire Flush D = 0;
pl_reg_fd      plfd (clk, StallD, FlushD, Instr, PC, PCPlus4, InstrD, PCD, PCPlus4D);

// register file logic
reg_file       rf (clk, RegWriteW, Rs1D, Rs2D, RdW, Result, RD1D, RD2D);
imm_extend     ext (InstrD[31:7], ImmSrcD, ImmExtD);

// Pipeline Register 2 -> Decode | Execute
pl_reg_de		plde(clk, FlushE, 
					RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, 
					ALUSrcD, JalrD, luiD, RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D, unsignD, funct3D,
					RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, 
					ALUSrcE, JalrE, luiE, RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E, unsignE, funct3E);

adder          pcaddbranch(PCE, ImmExtE, PCTarget);
					
// ALU logic
mux3 #(32)     SrcAFW_Mux (RD1E, Result, ALUResultM, ForwardAE, SrcAE);
mux3 #(32)     SrcBFW_Mux (RD2E, Result, ALUResultM, ForwardBE, WriteDataE);

mux2 #(32)     srcbmux(WriteDataE, ImmExtE, ALUSrcE, SrcBE);
alu            alu (SrcAE, SrcBE, unsignE, ALUControlE, ALUResultE, Zero, Cout);
adder #(32)    auipcadder (ImmExtE, PCE, AuiPCE);
mux2 #(32)     lauipcmux (AuiPCE, ImmExtE, luiE, lAuiPCE);

branching_unit bu (funct3E, Zero, ALUResultE[31], Cout, TakeBranch);

// Pipeline Register 3 -> Execute | Memory
pl_reg_em		plem(clk, RegWriteE, ResultSrcE, MemWriteE, ALUResultE, WriteDataE, lAuiPCE, RdE, PCE, PCPlus4E, funct3E,
								 RegWriteM, ResultSrcM, MemWriteM, ALUResultM, WriteDataM, lAuiPCM, RdM, PCM, PCPlus4M, funct3M);

// Pipeline Register 4 -> Memory | Writeback
pl_reg_mw      plmw(clk, RegWriteM, ResultSrcM, ALUResultM, ReadDataM, lAuiPCM, RdM, PCM, PCPlus4M, WriteDataM, 
                         RegWriteW, ResultSrcW, ALUResultW, ReadDataW, lAuiPCW, RdW, PCW, PCPlus4W, WriteDataW);

// Result Source
mux4 #(32)     resultmux(ALUResultW, ReadDataW, PCPlus4W, lAuiPCW, ResultSrcW, Result);

// hazard unit

hazard_unit   hu (Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW, PCSrc, RegWriteM, RegWriteW, ResultSrcE[0], 
					  StallF, StallD, FlushD, FlushE, ForwardAE, ForwardBE);

assign Mem_WrData = WriteDataM;
assign Mem_WrAddr = ALUResultM;

// eventually this statements will be removed while adding pipeline registers
//assign PCW = (PCW > 1'b0) ? (PCPlus4W - 2'd4) : 0;
//assign ALUResultW = ALUResult;
//assign WriteDataW = WriteData;

endmodule
