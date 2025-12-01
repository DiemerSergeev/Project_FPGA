`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2025 13:27:04
// Design Name: 
// Module Name: TOPI
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


module TOPI( input clk, input rst);

logic [29:0] count_mesh;

always_ff @ (posedge clk)
    if (rst) count_mesh <= 30'd0;
    else if  (count_mesh==30'd101010000000000000000000000000) count_mesh <= 30'd0;
    else count_mesh <= count_mesh + 30'd1;
endmodule
