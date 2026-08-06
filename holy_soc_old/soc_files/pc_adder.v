`timescale 1ns / 1ps

module pc_adder(
    input  [31:0] pc,
    output [31:0] pc_plus_4
    );
    
    assign pc_plus_4 = pc + 4;
    
endmodule
