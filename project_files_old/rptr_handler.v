`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 12:50:38
// Design Name: 
// Module Name: rptr_handler
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

module rptr_handler(
    input rclk,
    input rst,
    input r_en,
    
    output reg [4:0] rptr,
    output [3:0] raddr
    );
    reg [4:0] rbin;
    wire [4:0] rgray_next;
    wire [4:0] rbin_next;
    
    assign rbin_next = rbin + r_en;
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;
    assign raddr = rbin[3:0];
    always@(posedge rclk) begin
        if(rst) begin 
            rbin<=5'b0;
            rptr<=5'b0;
        end
        else begin 
            rbin<=rbin_next;
            rptr<=rgray_next;
        end
    end
endmodule
