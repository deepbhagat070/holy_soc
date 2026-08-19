`timescale 1ns / 1ps

module aes_core(
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] round_key,
    output reg  [127:0] ciphertext,
    output reg          done
);

    localparam IDLE       = 3'b000;
    localparam CHECK_KEY  = 3'b001;
    localparam EXPAND_KEY = 3'b010;
    localparam RUNNING    = 3'b011;
    localparam DONE_ST    = 3'b100;

    reg [2:0]   state;
    reg [3:0]   round_counter;
    
    reg  [127:0] prev_round_key;
    reg          start_exp;
    wire         key_ready;
    wire [1407:0] round_keys_flat;

    aes_key_expansion my_key_expansion (
        .clk             (clk),
        .reset           (reset),
        .start_exp       (start_exp),
        .cipher_key      (round_key),
        .key_ready       (key_ready),
        .round_keys_flat (round_keys_flat)
    );

    wire [127:0] round_in;
    wire [127:0] round_out;
    reg  [127:0] feedback_reg;
    wire         is_final;

    wire [127:0] whitened_plaintext = plaintext ^ round_keys_flat[127:0];
    assign round_in = (round_counter == 4'd1) ? whitened_plaintext : feedback_reg;
    assign is_final = (round_counter == 4'd10) ? 1'b1 : 1'b0;
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
            state          <= IDLE;
            round_counter  <= 4'd0;
            done           <= 1'b0;
            ciphertext     <= 128'd0;
            feedback_reg   <= 128'd0;
            start_exp      <= 1'b0;
            prev_round_key <= 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= CHECK_KEY;
                    end
                end

                CHECK_KEY: begin
                    if (round_key != prev_round_key) begin
                        start_exp <= 1'b1;
                        state     <= EXPAND_KEY;
                    end else begin
                        round_counter <= 4'd1;
                        state         <= RUNNING;
                    end
                end

                EXPAND_KEY: begin
                    if (key_ready) begin
                        start_exp      <= 1'b0;
                        prev_round_key <= round_key;
                        round_counter  <= 4'd1;
                        state          <= RUNNING;
                    end
                end

                RUNNING: begin
                    feedback_reg <= round_out;
                    if (round_counter == 4'd10) begin
                        state      <= DONE_ST;
                        ciphertext <= round_out;
                    end else begin
                        round_counter <= round_counter + 1'b1;
                    end
                end

                DONE_ST: begin
                    done <= 1'b1;
                    if (!start) begin
                        state         <= IDLE;
                        round_counter <= 4'd0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule