`timescale 1ns / 1ps

`timescale 1ns / 1ps

module aes_round(
    input  wire         clk,            
    input  wire [127:0] data_in,
    input  wire [127:0] round_key,
    input  wire         is_final_round,
    output wire [127:0] data_out
);

    wire [127:0] sb_out;
    wire [127:0] sr_out;
    wire [127:0] mc_out;
    wire [127:0] add_key_in;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_array
            aes_sbox sbox_inst (
                .data_in  ( data_in[i*8 +: 8] ),
                .data_out ( sb_out[i*8 +: 8]  )
            );
        end
    endgenerate
    

    aes_shift_rows shift_rows_inst (
        .data_in  ( sb_out ),
        .data_out ( sr_out )
    );
    
    aes_mix_columns mix_columns_inst (
        .data_in  ( sr_out ),
        .data_out ( mc_out )
    );

    assign add_key_in = (is_final_round == 1'b1) ? sr_out : mc_out;

    aes_add_round_key add_round_key_inst (
        .data_in   ( add_key_in ),
        .round_key ( round_key ),
        .data_out  ( data_out )
    );

endmodule