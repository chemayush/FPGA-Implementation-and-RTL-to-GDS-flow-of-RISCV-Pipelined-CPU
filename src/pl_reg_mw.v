
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

