
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
		  4'b1111:  alu_out = (a >> b[4:0]) | ({32{a[WIDTH-1]}} << (WIDTH - b[4:0]));  // srai
		  4'b1010:  alu_out <= a >> b[4:0];       // srli
		  4'b1011:  alu_out <= a << b[4:0];  // sll, slli
		  
        default: alu_out = 0;
    endcase
end

assign cout = sum_result[WIDTH];
assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule



