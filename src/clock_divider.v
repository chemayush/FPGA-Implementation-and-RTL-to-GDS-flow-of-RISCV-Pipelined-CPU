`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.12.2024 11:19:05
// Design Name: 
// Module Name: clock_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module clock_divider(
    input clk_in,
    output reg clk_out  // Output clock
);

// Counter to keep track of clock cycles
reg [3:0] count;    // 3 bits needed to count up to 5

initial begin
    clk_out = 1;
    count = 0; 
end



    // Counter logic
    always @(posedge clk_in) begin
        if (count == 4'd9) begin    // Count to 4 (0 to 4 = 5 cycles)
            count <= 4'd0;          // Reset counter
            clk_out <= ~clk_out;    // Toggle output clock
        end else begin
            count <= count + 1;     // Increment counter
        end
    end

endmodule


