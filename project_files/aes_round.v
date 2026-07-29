`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 13:38:36
// Design Name: 
// Module Name: aes_round
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

`timescale 1ns / 1ps

module aes_round(
    input  wire         clk,            // Maintained for interface compatibility, though unused in combinational logic
    input  wire [127:0] data_in,
    input  wire [127:0] round_key,
    input  wire         is_final_round,
    output wire [127:0] data_out
);

    wire [127:0] sb_out;
    wire [127:0] sr_out;
    wire [127:0] mc_out;
    wire [127:0] add_key_in;
    
    // =========================================================================
    // MODIFICATION 1: REMOVED PIPELINE REGISTER
    // The aes_core FSM evaluates 1 round per clock cycle. 
    // Inserting a clocked register here created a 2-cycle latency, breaking 
    // the pipeline timing synchronization.
    // =========================================================================

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_array
            aes_sbox sbox_inst (
                // =============================================================
                // MODIFICATION 2: SYNTAX CORRECTION
                // Replaced '[(i*8)+7 : i*8]' with Indexed Part-Select '+:'. 
                // This guarantees constant-width evaluation and prevents 
                // synthesis/elaboration toolchain crashes.
                // =============================================================
                .data_in  ( data_in[i*8 +: 8] ),
                .data_out ( sb_out[i*8 +: 8]  )
            );
        end
    endgenerate
    
    // =========================================================================
    // MODIFICATION 3: ROUTING UPDATE
    // sb_out now drives shift_rows_inst directly as a pure combinational path.
    // =========================================================================
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