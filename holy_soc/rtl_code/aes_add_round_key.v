`timescale 1ns / 1ps


module aes_add_round_key(
    input  wire [127:0] data_in,
    input  wire [127:0] round_key,
    output wire [127:0] data_out
);

    assign data_out = data_in ^ round_key;
endmodule