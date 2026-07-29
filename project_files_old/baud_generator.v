`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 14:42:37
// Design Name: 
// Module Name: baud_generator
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


module baud_generator
    #(parameter Max_count = 868)

    (
    input clk,
    input rst,
    output reg tx_tick
    );
    
    
    reg [9:0]count; 
    always@(posedge clk) begin
        if(rst) begin  
            count <= 10'b0;
            tx_tick <= 1'b0;
        end
        else begin 
            if(count == (Max_count - 1)) begin
                count <= 10'b0;
                tx_tick <= 1'b1;
            end
            else begin 
                count <= count +1;
                tx_tick <= 1'b0;
            end 
        end
    end
endmodule
