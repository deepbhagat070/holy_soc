`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 15:31:07
// Design Name: 
// Module Name: synchronizer
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


module synchronizer(
    input clk,
    input rst,
    input [4:0] d_in,
    output reg [4:0] d_out
    );
    reg [4:0] q1;
    always@(posedge clk) begin
        if(rst) begin
            q1<=5'b0;
            d_out<=5'b0;
        end
        else begin 
            q1<=d_in;
            d_out<=q1;
        end
    end
endmodule
