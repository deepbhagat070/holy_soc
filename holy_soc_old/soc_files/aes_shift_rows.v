`timescale 1ns / 1ps

module aes_shift_rows(
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    wire [7:0] b0  = data_in[127:120];
    wire [7:0] b1  = data_in[119:112];
    wire [7:0] b2  = data_in[111:104];
    wire [7:0] b3  = data_in[103:96];
    
    wire [7:0] b4  = data_in[95:88];
    wire [7:0] b5  = data_in[87:80];
    wire [7:0] b6  = data_in[79:72];
    wire [7:0] b7  = data_in[71:64];
    
    wire [7:0] b8  = data_in[63:56];
    wire [7:0] b9  = data_in[55:48];
    wire [7:0] b10 = data_in[47:40];
    wire [7:0] b11 = data_in[39:32];
    
    wire [7:0] b12 = data_in[31:24];
    wire [7:0] b13 = data_in[23:16];
    wire [7:0] b14 = data_in[15:8];
    wire [7:0] b15 = data_in[7:0];

    assign data_out = {b0, b5, b10, b15, b4, b9, b14, b3, b8, b13, b2, b7, b12, b1, b6, b11};
    
endmodule
