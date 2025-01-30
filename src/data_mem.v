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
