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

