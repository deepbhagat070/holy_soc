`timescale 1ns / 1ps


module aes_mix_columns(
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = (b[7] == 1'b1) ? ((b << 1) ^ 8'h1B) : (b << 1);
        end
    endfunction

    function [31:0] mix_column;
        input [31:0] col;
        reg [7:0] b0, b1, b2, b3;
        reg [7:0] new_b0, new_b1, new_b2, new_b3;
        begin
            b0 = col[31:24];
            b1 = col[23:16];
            b2 = col[15:8];
            b3 = col[7:0];

            new_b0 = xtime(b0) ^ (xtime(b1) ^ b1) ^ b2 ^ b3;
            new_b1 = b0 ^ xtime(b1) ^ (xtime(b2) ^ b2) ^ b3;
            new_b2 = b0 ^ b1 ^ xtime(b2) ^ (xtime(b3) ^ b3);
            new_b3 = (xtime(b0) ^ b0) ^ b1 ^ b2 ^ xtime(b3);

            mix_column = {new_b0, new_b1, new_b2, new_b3};
        end
    endfunction

    wire [31:0] col0 = data_in[127:96];
    wire [31:0] col1 = data_in[95:64];
    wire [31:0] col2 = data_in[63:32];
    wire [31:0] col3 = data_in[31:0];

    assign data_out = {
        mix_column(col0),
        mix_column(col1),
        mix_column(col2),
        mix_column(col3)
    };

endmodule
