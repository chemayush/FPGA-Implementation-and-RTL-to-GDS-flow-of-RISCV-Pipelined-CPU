
// adder.v - logic for adder

module adder #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,
    output      [WIDTH-1:0] sum
);

assign sum = a + b;

endmodule


// alu.v - ALU module

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
	 input       unsign,
    input       [3:0] alu_ctrl,         // ALU control
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero, cout              // zero flag
);

reg [WIDTH:0] sum_result;

always @(a, b, alu_ctrl, unsign) begin
    case (alu_ctrl)
        4'b0000:  begin
				sum_result = a + b;
				alu_out <= sum_result[WIDTH-1:0];       // ADD
			end
        4'b0001:  begin
				sum_result = a + ~b + 1;
				alu_out <= sum_result[WIDTH-1:0];       // ADD
			end
        4'b0010:  alu_out <= a & b;       // AND
        4'b0011:  alu_out <= a | b;       // OR
        4'b0101:  begin                   // SLT
                     if (unsign) alu_out <= ($unsigned(a) < $unsigned(b));
                     else alu_out <= ($signed(a) < $signed(b));
                 end
		  4'b0110:  alu_out <= a ^ b;		 // XOR
		  4'b0111:  alu_out <= a >>> b[4:0]; // sra
		  4'b1000:  alu_out <= a >> b[4:0];  // srl
		  4'b1111:  alu_out <= (a >> b[4:0]) | ({32{a[WIDTH-1]}} << (WIDTH - b[4:0]));  // srai
		  4'b1010:  alu_out <= a >> b[4:0];       // srli
		  4'b1011:  alu_out <= a << b[4:0];  // sll, slli
		  
        default: alu_out <= 0;
    endcase
end

assign cout = sum_result[WIDTH];
assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule


// alu_decoder.v - logic for ALU decoder

module alu_decoder (
    input            opb5,
    input [2:0]      funct3,
    input            funct7b5,
    input [1:0]      ALUOp,
    output reg [3:0] ALUControl,
	 output unsign
);

reg us;

always @(*) begin
	 us = 0;
    case (ALUOp)
        2'b00: ALUControl = 4'b0000;             // addition
        2'b01: ALUControl = 4'b0001;             // subtraction
        default:
            case (funct3) // R-type or I-type ALU
                3'b000: begin
                    // True for R-type subtract
                    if   (funct7b5 & opb5) ALUControl = 3'b001; //sub
                    else ALUControl = 4'b0000; // add, addi
                end
					 3'b001:  ALUControl = 4'b1011; // sll, slli
                3'b010:  ALUControl = 4'b0101; // slt, slti
					 3'b011: begin 
							ALUControl = 4'b0101; us = 1; // sltu, sltiu
					 end
					 3'b100:  ALUControl = 4'b0110;  // xor, xori
					 3'b101: begin
							if (funct7b5 == 1 && opb5 == 1) ALUControl = 4'b0111; 			// sra
							else if (funct7b5 == 0 & opb5 == 1) ALUControl = 4'b1000; 	// srl
							else if (funct7b5 == 1 & opb5 == 0) ALUControl = 4'b1111; 	// srai
							else if (funct7b5 == 0 & opb5 == 0) ALUControl = 4'b1010;  // srli
					 end
                3'b110:  ALUControl = 4'b0011; // or, ori
                3'b111:  ALUControl = 4'b0010; // and, andi
                default: ALUControl = 4'bxxxx; // ???
            endcase
    endcase
end

assign unsign = us;

endmodule


// branching_unit.v - logic for branching in execute stage

module branching_unit (
    input [2:0] funct3,
    input       Zero, ALUR31, Cout,
    output reg  Branch
);

initial begin
    Branch = 1'b0;
end

always @(*) begin
    case (funct3)
        3'b000: Branch =    Zero; // beq
        3'b001: Branch =   !Zero; // bne
        3'b101: Branch = !ALUR31; // bge
		  3'b100: Branch =  ALUR31; // blt
		  3'b110: Branch =    Cout; // bltu
		  3'b111: Branch =   !Cout; // bgeu
        default: Branch = 1'b0;
    endcase
end

endmodule



// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       ALUSrc,
    output       RegWrite, Branch, Jump, Jalr, lui,
    output [2:0] ImmSrc,
    output [3:0] ALUControl,
	 output unsign
);

wire [1:0] ALUOp;

main_decoder    md (op, funct3, ResultSrc, MemWrite, Branch,
                    ALUSrc, RegWrite, Jump, Jalr, lui, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl, unsign);

endmodule

// data_mem.v - data memory
module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 64) (
    input       clk, rst_n, wr_en,
    input [2:0] funct3,
    input       [ADDR_WIDTH-1:0] wr_addr, wr_data,
    output reg  [DATA_WIDTH-1:0] rd_data_mem,
    output      correct
);

// array of 64 32-bit words or data
reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];
wire [ADDR_WIDTH-1:0] word_addr = wr_addr[DATA_WIDTH-1:2] % 64;
integer i;

// synchronous write logic
always @(posedge clk) begin
    if (rst_n) begin
        // Reset all memory locations to 0
        //integer i;
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            data_ram[i] <= 32'h0;
        end
        // Set initial values
        data_ram[0] <= 32'h0000001c;
        data_ram[1] <= 32'h00000010;
        data_ram[2] <= 32'h00000000;
        data_ram[3] <= 32'h00000000;
    end else if (wr_en) begin
        case (funct3)
            3'b000: begin // sb
                case (wr_addr[1:0])
                    2'b00: data_ram[word_addr][ 7: 0] = wr_data[7:0];
                    2'b01: data_ram[word_addr][15: 8] = wr_data[7:0];
                    2'b10: data_ram[word_addr][23:16] = wr_data[7:0];
                    2'b11: data_ram[word_addr][31:24] = wr_data[7:0];
                endcase
            end
            3'b001: begin // sh
                case (wr_addr[1])
                    1'b0: data_ram[word_addr][15: 0] = wr_data[15:0];
                    1'b1: data_ram[word_addr][31:16] = wr_data[15:0];
                endcase
            end
            3'b010: data_ram[word_addr] <= wr_data; // sw
        endcase
    end
end

assign correct = (
                      (data_ram[52][7:0]   == 8'd28) 
                    & (data_ram[52][15:8]  == 8'd30) 
                    & (data_ram[52][23:16] == 8'd23) 
                    & (data_ram[52][31:24] == 8'd21) 
                    & (data_ram[53][7:0]   == 8'd18) 
                    & (data_ram[53][15:8]  == 8'd16)
                  ) ? 1'b1 : 1'b0;

// combinational read logic
always @(*) begin
    case (funct3)
        3'b000: begin // lb
            case (wr_addr[1:0])
                2'b00: rd_data_mem = {{24{data_ram[word_addr][ 7]}}, data_ram[word_addr][ 7: 0]};
                2'b01: rd_data_mem = {{24{data_ram[word_addr][15]}}, data_ram[word_addr][15: 8]};
                2'b10: rd_data_mem = {{24{data_ram[word_addr][23]}}, data_ram[word_addr][23:16]};
                2'b11: rd_data_mem = {{24{data_ram[word_addr][31]}}, data_ram[word_addr][31:24]};
            endcase
        end
		  
        3'b001: begin // lh (load halfword)
				  case (wr_addr[1])
						1'b0: rd_data_mem = {{16{data_ram[word_addr][15]}}, data_ram[word_addr][15:0]};
						1'b1: rd_data_mem = {{16{data_ram[word_addr][31]}}, data_ram[word_addr][31:16]};
				  endcase
        end
		  
        3'b010: rd_data_mem = data_ram[word_addr]; // lw

        3'b100: begin // lbu
            case (wr_addr[1:0])
                2'b00: rd_data_mem = {{24'b0}, data_ram[word_addr][ 7: 0]};
                2'b01: rd_data_mem = {{24'b0}, data_ram[word_addr][15: 8]};
                2'b10: rd_data_mem = {{24'b0}, data_ram[word_addr][23:16]};
                2'b11: rd_data_mem = {{24'b0}, data_ram[word_addr][31:24]};
            endcase
        end

        3'b101: begin // lhu (load halfword unsigned)
            case (wr_addr[1])
                1'b0: rd_data_mem = {16'b0, data_ram[word_addr][15:0]};
                1'b1: rd_data_mem = {16'b0, data_ram[word_addr][31:16]};
            endcase
        end


    endcase
end

endmodule


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

module hazard_unit(
		
		input      [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
		input            PCSrcE, RegWriteM, RegWriteW, ResultSrcE0,
		output           StallF, StallD, FlushD, FlushE,
		output reg [1:0] ForwardAE, ForwardBE
);

wire lwStall;

always @(*) begin

	ForwardAE = 2'b00;
	ForwardBE = 2'b00;

	if (((Rs1E == RdM) & RegWriteM) & (Rs1E != 0))
		ForwardAE = 2'b10;	
	else if (((Rs1E == RdW) & RegWriteW) & (Rs1E != 0))
		ForwardAE = 2'b01;
	else
		ForwardAE = 2'b00;
		
	if (((Rs2E == RdM) & RegWriteM) & (Rs2E != 0))
		ForwardBE = 2'b10;	
	else if (((Rs2E == RdW) & RegWriteW) & (Rs2E != 0))
		ForwardBE = 2'b01;
	else
		ForwardBE = 2'b00;
		
end


assign lwStall = ((ResultSrcE0 == 1'b1) & ((Rs1D == RdE) | (Rs2D == RdE))) ? 1'b1 : 1'b0;

assign StallF = lwStall;
assign StallD = lwStall;

assign FlushD = PCSrcE;
assign FlushE = lwStall | PCSrcE;


endmodule


// imm_extend.v - logic for sign extension
module imm_extend (
    input  [31:7]     instr,
    input  [ 2:0]     immsrc,
    output reg [31:0] immext
);

always @(*) begin
    case(immsrc)
        // I−type
        3'b000:   immext = {{20{instr[31]}}, instr[31:20]};
        // S−type (stores)
        3'b001:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        // B−type (branches)
        3'b010:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        // J−type (jal)
        3'b011:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
		  // U-type
		  3'b100:   immext = {instr[31:12], 12'b0};
        default: immext = 32'bx; // undefined
    endcase
end

endmodule


// instr_mem.v - instruction memory

module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 512) (
    input       [ADDR_WIDTH-1:0] instr_addr,
    output      [DATA_WIDTH-1:0] instr
);

// array of 64 32-bit words or instructions
reg [DATA_WIDTH-1:0] instr_ram [0:MEM_SIZE-1];

initial begin
    $readmemh("program.mem", instr_ram);
end

assign instr = instr_ram[instr_addr[31:2]];

endmodule


// main_decoder.v - logic for main decoder

module main_decoder (
    input  [6:0] op,
    input  [2:0] funct3,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output       RegWrite, Jump, Jalr, lui,
    output [2:0] ImmSrc,
    output [1:0] ALUOp
);

reg [13:0] controls;

always @(*) begin
    casez (op)
        // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_ALUOp_Jump_Jalr_Branch_lui
        7'b0000011: controls = 14'b1_000_1_0_01_00_0_0_0_0; // lw
        7'b0100011: controls = 14'b0_001_1_1_00_00_0_0_0_0; // sw
        7'b0110011: controls = 14'b1_xxx_0_0_00_10_0_0_0_0; // R–type
        7'b1100011: begin // branch
            controls = 14'b0_010_0_0_00_01_0_0_1_0;
        end
        7'b0010011: controls = 14'b1_000_1_0_00_10_0_0_0_0; // I–type ALU
        7'b1101111: controls = 14'b1_011_0_0_10_00_1_0_0_0; // jal
        7'b1100111: controls = 14'b1_000_1_0_10_00_0_1_0_0; // jalr
        7'b0110111: controls = 14'b1_100_x_0_11_xx_0_0_0_1; // lui
		  7'b0010111: controls = 14'b1_100_x_0_11_xx_0_0_0_0; // auipc
        default:    controls = 14'b0_000_0_0_00_00_0_0_0_0; // ???
    endcase
end

assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, ALUOp, Jump, Jalr, Branch, lui} = controls;

endmodule


// mux2.v - logic for 2-to-1 multiplexer

module mux2 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1,
    input       sel,
    output      [WIDTH-1:0] y
);

assign y = sel ? d1 : d0;

endmodule


// mux3.v - logic for 3-to-1 multiplexer

module mux3 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1, d2,
    input       [1:0] sel,
    output      [WIDTH-1:0] y
);

assign y = sel[1] ? d2: (sel[0] ? d1 : d0);

endmodule


// mux4.v - logic for 4-to-1 multiplexer

module mux4 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1, d2, d3,
    input       [1:0] sel,
    output      [WIDTH-1:0] y
);

assign y = sel[1] ? (sel[0] ? d3 : d2) : (sel[0] ? d1 : d0);

endmodule

// pipeline registers -> decode | execute stage
module pl_reg_de (
    input             clk, clr,
     input                 RegWriteD, 
     input        [ 1:0] ResultSrcD,
     input                 MemWriteD, JumpD, BranchD, 
     input        [ 3:0] ALUControlD,
     input                 ALUSrcD,
	  input 					 JalrD, luiD,

     input        [31:0] RD1D, RD2D,
     input        [31:0] PCD,
     input        [ 4:0] Rs1D, Rs2D, RdD,
     input        [31:0] ImmExtD, PCPlus4D,
	  input               unsignD,
	  input        [ 2:0] funct3D, 

     output reg              RegWriteE, 
     output reg       [ 1:0] ResultSrcE,
     output reg              MemWriteE, JumpE, BranchE, 
     output reg       [ 3:0] ALUControlE,
     output reg              ALUSrcE,
	  output reg              JalrE, luiE,

     output reg       [31:0] RD1E, RD2E,
     output reg       [31:0] PCE,
     output reg       [ 4:0] Rs1E, Rs2E, RdE,
     output reg       [31:0] ImmExtE, PCPlus4E,
	  output reg              unsignE,
	  output reg       [ 2:0] funct3E
);

initial begin
     RegWriteE = 0; ResultSrcE = 0; MemWriteE = 0; JumpE = 0; BranchE = 0; ALUControlE = 0; ALUSrcE = 0; funct3E = 0;
	  JalrE = 0; luiE = 0; RD1E = 0; RD2E = 0; PCE = 0; Rs1E = 0; Rs2E = 0; RdE = 0; ImmExtE = 0; PCPlus4E = 0; unsignE = 0;
end
always @(posedge clk) begin
    if (clr) begin
        RegWriteE <= 0; ResultSrcE <= 0; MemWriteE <= 0; JumpE <= 0; BranchE <= 0; ALUControlE <= 0; ALUSrcE <= 0; funct3E <= 0;
        JalrE <= 0; luiE <= 0; RD1E <= 0; RD2E <= 0; PCE <= 0; Rs1E <= 0; Rs2E <= 0; RdE <= 0; ImmExtE <= 0; PCPlus4E <= 0; unsignE <= 0;
    end else begin
        RegWriteE <= RegWriteD; 
        ResultSrcE <= ResultSrcD; 
        MemWriteE <= MemWriteD; 
        JumpE <= JumpD; 
        BranchE <= BranchD; 
        ALUControlE <= ALUControlD; 
        ALUSrcE <= ALUSrcD;
		  JalrE <= JalrD; 
		  luiE <= luiD;
        RD1E <= RD1D; 
        RD2E <= RD2D; 
        PCE <= PCD; 
        Rs1E <= Rs1D; 
        Rs2E <= Rs2D; 
        RdE <= RdD; 
        ImmExtE <= ImmExtD; 
        PCPlus4E <= PCPlus4D;
		  unsignE <= unsignD;
		  funct3E <= funct3D;
    end
end
endmodule


// pipeline registers -> execute | memory stage

module pl_reg_em (
    input             clk,
	 input				 RegWriteE, 
	 input		[ 1:0] ResultSrcE,
	 input				 MemWriteE,
	 
	 input      [31:0] ALUResultE, WriteDataE, lAuiPCE,
	 input		[ 4:0] RdE,
	 input		[31:0] PCE, PCPlus4E,
	 input      [ 2:0] funct3E, 

	 output	reg		  RegWriteM, 
	 output	reg [ 1:0] ResultSrcM,
	 output	reg		  MemWriteM,
	 
	 output reg [31:0] ALUResultM, WriteDataM, lAuiPCM,
	 output reg [ 4:0] RdM,
	 output reg [31:0] PCM, PCPlus4M,
	 output reg [ 2:0] funct3M
);

initial begin

	 RegWriteM = 0; ResultSrcM = 0; MemWriteM = 0; ALUResultM = 0; WriteDataM = 0; RdM = 0; PCPlus4M = 0; PCM = 0; lAuiPCM = 0; funct3M = 0;
end

always @(posedge clk) begin
	 RegWriteM <= RegWriteE; 
	 ResultSrcM <= ResultSrcE; 
	 MemWriteM <= MemWriteE; 
	 ALUResultM <= ALUResultE; 
	 WriteDataM <= WriteDataE; 
	 RdM <= RdE; 
	 PCM <= PCE;
	 PCPlus4M <= PCPlus4E;
	 lAuiPCM <= lAuiPCE;
	 funct3M <= funct3E;
end

endmodule


// pipeline registers -> fetch | decode stage

module pl_reg_fd (
    input             clk, en, clr,
    input      [31:0] InstrF, PCF, PCPlus4F,
    output reg [31:0] InstrD, PCD, PCPlus4D
);

initial begin
    InstrD = 0; PCD = 0; PCPlus4D = 0;
end

always @(posedge clk) begin
    if (clr) begin
        InstrD <= 0; PCD <= 0; PCPlus4D <= 0;
    end else if (!en) begin
        InstrD <= InstrF; PCD <= PCF;
        PCPlus4D <= PCPlus4F;
    end
end

endmodule


// pipeline registers -> memory | writeback stage

module pl_reg_mw (
    input             clk,
	 
	 input				 RegWriteM, 
	 input		[ 1:0] ResultSrcM,
	 
	 input      [31:0] ALUResultM, ReadDataM, lAuiPCM,
	 input		[ 4:0] RdM,
	 input		[31:0] PCM, PCPlus4M, WriteDataM,

	 output	reg		  RegWriteW, 
	 output	reg [ 1:0] ResultSrcW,
	 
	 output reg [31:0] ALUResultW, ReadDataW, lAuiPCW,
	 output reg [ 4:0] RdW,
	 output reg [31:0] PCW, PCPlus4W, WriteDataW
);

initial begin
	 RegWriteW = 0; ResultSrcW = 0; ALUResultW = 0; ReadDataW = 0; RdW = 0; PCPlus4W = 0; PCW = 0; lAuiPCW = 0; WriteDataW = 0;
end

always @(posedge clk) begin
	 RegWriteW <= RegWriteM; 
	 ResultSrcW <= ResultSrcM; 
	 ALUResultW <= ALUResultM; 
	 ReadDataW <= ReadDataM; 
	 RdW <= RdM; 
	 PCW <= PCM;
	 PCPlus4W <= PCPlus4M;
	 lAuiPCW <= lAuiPCM;
	 WriteDataW <= WriteDataM;
end

endmodule

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


// reg_file.v - register file for single-cycle RISC-V CPU
//              (with 32 registers, each of 32 bits)
//              having two read ports, one write port
//              write port is synchronous, read ports are combinational
//              register 0 is hardwired to 0

module reg_file #(parameter DATA_WIDTH = 32) (
    input       clk,
    input       wr_en,
    input       [4:0] rd_addr1, rd_addr2, wr_addr,
    input       [DATA_WIDTH-1:0] wr_data,
    output      [DATA_WIDTH-1:0] rd_data1, rd_data2
);

reg [DATA_WIDTH-1:0] reg_file_arr [0:31];

initial begin
    reg_file_arr[0] = 0; // hardwired x0 - 0
end

// register file write logic (synchronous)
always @(negedge clk) begin
    if (wr_en) reg_file_arr[wr_addr] <= wr_data;
end

// register file read logic (combinational)
assign rd_data1 = ( rd_addr1 != 0 ) ? reg_file_arr[rd_addr1] : 0;
assign rd_data2 = ( rd_addr2 != 0 ) ? reg_file_arr[rd_addr2] : 0;

endmodule


// reset_ff.v - 32-bit resettable D flip-flop

module reset_ff #(parameter WIDTH = 32) (
    input       clk, rst, clr,
    input       [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

initial begin
    q = 0;
end

always @(posedge clk) begin
    if (rst) q <= 0;
    else if (!clr) q <= d;
end

endmodule


// riscv_cpu.v - single-cycle RISC-V CPU Processor

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
