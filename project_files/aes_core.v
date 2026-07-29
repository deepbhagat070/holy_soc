`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: aes_core
//
// FIXES APPLIED (see conversation for full explanation):
//   1. Added aes_key_expansion instance -- previously the SAME static
//      128-bit key was fed into every round. Real AES-128 needs a
//      different round key per round, derived via the key schedule.
//   2. Added the initial "whitening" AddRoundKey (plaintext XOR round
//      key 0) BEFORE round 1's SubBytes. This step was missing
//      entirely -- the old code went straight into SubBytes on raw
//      plaintext.
//   3. Fixed round count: was 15 rounds (0..14, an AES-256-shaped
//      count), now correctly 10 rounds (1..10) for AES-128.
//
// External interface (ports) is UNCHANGED from the original file --
// aes_wrapper.v does not need any modification. `round_key` is now
// correctly documented as the ORIGINAL 128-bit cipher key (which it
// always was, semantically -- it just wasn't being expanded before).
//////////////////////////////////////////////////////////////////////////////////

module aes_core(
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] round_key,    // the original 128-bit cipher key
    output reg  [127:0] ciphertext,
    output reg          done
);

    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam DONE    = 2'b10;

    reg [1:0] state;
    reg [3:0] round_counter;   // now runs 1..10 (AES-128 round numbering)

    wire [127:0] round_in;
    wire [127:0] round_out;
    reg  [127:0] feedback_reg;
    wire         is_final;

    // ---------------------------------------------------------------
    // NEW: Key schedule -- generates all 11 round keys once from the
    // input cipher key (purely combinational, based on a fixed input).
    // ---------------------------------------------------------------
    wire [1407:0] round_keys_flat;

    aes_key_expansion my_key_expansion (
        .cipher_key     (round_key),
        .round_keys_flat(round_keys_flat)
    );

    // FIX (compile error): the original code declared `wire [127:0]
    // rk [0:10]` (an array of nets) and read it as `rk[round_counter]`
    // -- indexing a net array with a runtime variable (round_counter)
    // in a continuous assignment is illegal Verilog. Indexed
    // part-select (+:) supports a VARIABLE base index directly on a
    // flat vector, so we read round_keys_flat that way instead and
    // never need the rk[] array at all.

    // NEW: initial whitening step -- plaintext XOR round key 0,
    // applied BEFORE round 1's SubBytes (previously missing).
    wire [127:0] whitened_plaintext = plaintext ^ round_keys_flat[127:0];

    // round_counter==1 is the first real round, fed the whitened
    // plaintext instead of raw plaintext.
    assign round_in = (round_counter == 4'd1) ? whitened_plaintext : feedback_reg;

    // FIX: final round is round 10 for AES-128, not round 14.
    assign is_final = (round_counter == 4'd10) ? 1'b1 : 1'b0;

    // FIX: select THIS round's key from the schedule instead of
    // reusing the same static key every round. `+:` supports a
    // variable base index -- this is legal where rk[round_counter]
    // was not.
    wire [127:0] this_round_key = round_keys_flat[128*round_counter +: 128];

    aes_round my_aes_round (
        .clk            (clk),
        .data_in        ( round_in ),
        .round_key      ( this_round_key ),
        .is_final_round ( is_final ),
        .data_out       ( round_out )
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            round_counter <= 4'd0;
            done          <= 1'b0;
            ciphertext    <= 128'd0;
            feedback_reg  <= 128'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state         <= RUNNING;
                        round_counter <= 4'd1;   // FIX: start at round 1
                    end
                end

                RUNNING: begin
                    feedback_reg <= round_out;
                    if (round_counter == 4'd10) begin   // FIX: was 14
                        state      <= DONE;
                        ciphertext <= round_out;
                    end else begin
                        round_counter <= round_counter + 1'b1;
                    end
                end

                DONE: begin
                    done <= 1'b1;
                    if (!start) begin
                        state <= IDLE;
                        round_counter <= 4'd0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule