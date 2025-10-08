`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2025 01:12:24 PM
// Design Name: 
// Module Name: dff
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

// Verilog module: dff
module dff #(
    parameter FLOP_WIDTH = 4,
    parameter RESET_VALUE = 0
)(
    input  wire  clk,
    input  wire  reset,
    input  wire  [FLOP_WIDTH-1:0] d,
    output reg   [FLOP_WIDTH-1:0] q
);
    
    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            q <= RESET_VALUE;
        end 
        else begin
            q <= d;
        end
    end  
endmodule
