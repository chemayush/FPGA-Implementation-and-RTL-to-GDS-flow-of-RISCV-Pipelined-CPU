
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

