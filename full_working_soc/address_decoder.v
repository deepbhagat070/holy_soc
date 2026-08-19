`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2026 19:02:53
// Design Name: 
// Module Name: address_decoder
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


module address_decoder(
    input wire [31:0] cpu_addr,
    
    output reg ram_en,
    output reg aes_en,
    output reg uart_en
    );
    
    always@(*) begin
    ram_en=1'b0;
    aes_en=1'b0;
    uart_en=1'b0;
    
    if(cpu_addr[31:28] == 4'h0) ram_en=1'b1;
    else if(cpu_addr[31:28] == 4'h4) aes_en=1'b1;
    else if(cpu_addr[31:28] == 4'h8) uart_en=1'b1;
    end
endmodule
