`timescale 1ns / 1ps


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
