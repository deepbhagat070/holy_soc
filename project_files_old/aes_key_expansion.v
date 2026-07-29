`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: aes_key_expansion
// Description: AES-128 key schedule (FIPS-197 Section 5.2).
//
// Generates 11 round keys (128 bits each) from the original 128-bit
// cipher key:
//   round key 0      -> used for the INITIAL whitening AddRoundKey,
//                        applied to the plaintext BEFORE round 1's
//                        SubBytes (this step was previously missing
//                        entirely from aes_core.v).
//   round keys 1..9   -> used for the 9 main rounds.
//   round key 10       -> used for the 10th (final) round.
//
// Reuses the project's existing aes_sbox module for SubWord, so the
// key schedule stays consistent with whatever S-box table is already
// verified/used elsewhere in the cipher datapath.
//
// Port is a flattened bus (not an unpacked array) for broad Verilog
// tool compatibility: round_keys_flat[127:0]   = round key 0
//                       round_keys_flat[255:128] = round key 1
//                       ... etc, round key k occupies bits [128k +: 128]
//////////////////////////////////////////////////////////////////////////////////

module aes_key_expansion (
    input  wire [127:0] cipher_key,
    output wire [1407:0] round_keys_flat  // 11 x 128 bits = 1408 bits
);

    // w[0..43]: 44 x 32-bit words. w[0..3] = original key, split into
    // four 32-bit words. Each subsequent group of 4 words w[4k..4k+3]
    // forms round key k.
    wire [31:0] w [0:43];

    assign w[0] = cipher_key[127:96];
    assign w[1] = cipher_key[95:64];
    assign w[2] = cipher_key[63:32];
    assign w[3] = cipher_key[31:0];

    // Rcon values for round i = 1..10 (only the top byte is non-zero)
    function [31:0] rcon;
        input [3:0] i;
        begin
            case (i)
                4'd1:  rcon = 32'h01000000;
                4'd2:  rcon = 32'h02000000;
                4'd3:  rcon = 32'h04000000;
                4'd4:  rcon = 32'h08000000;
                4'd5:  rcon = 32'h10000000;
                4'd6:  rcon = 32'h20000000;
                4'd7:  rcon = 32'h40000000;
                4'd8:  rcon = 32'h80000000;
                4'd9:  rcon = 32'h1B000000;
                4'd10: rcon = 32'h36000000;
                default: rcon = 32'h00000000;
            endcase
        end
    endfunction

    genvar gi;
    generate
        for (gi = 4; gi < 44; gi = gi + 1) begin : key_sched
            if (gi % 4 == 0) begin : first_of_group
                wire [31:0] rot_word;
                wire [31:0] sub_word;

                // RotWord: rotate the 4 bytes left by one byte position
                assign rot_word = {w[gi-1][23:0], w[gi-1][31:24]};

                // SubWord: run each byte through the existing S-box
                aes_sbox sb0 (.data_in(rot_word[31:24]), .data_out(sub_word[31:24]));
                aes_sbox sb1 (.data_in(rot_word[23:16]), .data_out(sub_word[23:16]));
                aes_sbox sb2 (.data_in(rot_word[15:8]),  .data_out(sub_word[15:8]));
                aes_sbox sb3 (.data_in(rot_word[7:0]),   .data_out(sub_word[7:0]));

                assign w[gi] = w[gi-4] ^ sub_word ^ rcon(gi >> 2);
            end else begin : rest_of_group
                assign w[gi] = w[gi-4] ^ w[gi-1];
            end
        end
    endgenerate

    genvar gk;
    generate
        for (gk = 0; gk < 11; gk = gk + 1) begin : pack_round_keys
            assign round_keys_flat[128*gk +: 128] =
                {w[4*gk], w[4*gk+1], w[4*gk+2], w[4*gk+3]};
        end
    endgenerate

endmodule