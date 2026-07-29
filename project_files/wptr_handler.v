`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 12:29:49
// Design Name: 
// Module Name: wptr_handler
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


module wptr_handler(
    input wclk,
    input rst,
    input w_en,
    
    output reg [4:0] wptr,
    output [3:0] waddr
    );
    reg [4:0] wbin;
    wire [4:0] wgray_next;
    wire [4:0] wbin_next;
    
    assign wbin_next = wbin + w_en;
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;
    assign waddr = wbin[3:0];
    always@(posedge wclk) begin
        if(rst) begin 
            wbin<=5'b0;
            wptr<=5'b0;
        end
        else begin 
            wbin<=wbin_next;
            wptr<=wgray_next;
        end
    end
endmodule
