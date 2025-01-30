
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

