`timescale 1ns / 1ps

module aes_key_expansion (
    input  wire          clk,
    input  wire          reset,
    input  wire          start_exp,
    input  wire  [127:0] cipher_key,
    output reg           key_ready,
    output wire [1407:0] round_keys_flat
);

    reg [127:0] key_mem [0:10];
    reg [3:0]   round_idx;
    reg [1:0]   state;

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;

    wire [127:0] current_key = (round_idx == 4'd0) ? cipher_key : key_mem[round_idx - 1];
    
    wire [31:0] w0 = current_key[127:96];
    wire [31:0] w1 = current_key[95:64];
    wire [31:0] w2 = current_key[63:32];
    wire [31:0] w3 = current_key[31:0];

    wire [31:0] rot_word = {w3[23:0], w3[31:24]};
    wire [31:0] sub_word;

    aes_sbox sb0 (.data_in(rot_word[31:24]), .data_out(sub_word[31:24]));
    aes_sbox sb1 (.data_in(rot_word[23:16]), .data_out(sub_word[23:16]));
    aes_sbox sb2 (.data_in(rot_word[15:8]),  .data_out(sub_word[15:8]));
    aes_sbox sb3 (.data_in(rot_word[7:0]),   .data_out(sub_word[7:0]));

    reg [31:0] rcon;
    always @(*) begin
        case (round_idx)
            4'd1: rcon = 32'h01000000; 4'd2: rcon = 32'h02000000;
            4'd3: rcon = 32'h04000000; 4'd4: rcon = 32'h08000000;
            4'd5: rcon = 32'h10000000; 4'd6: rcon = 32'h20000000;
            4'd7: rcon = 32'h40000000; 4'd8: rcon = 32'h80000000;
            4'd9: rcon = 32'h1B000000; 4'd10:rcon = 32'h36000000;
            default: rcon = 32'h00000000;
        endcase
    end

    wire [31:0] next_w0 = w0 ^ sub_word ^ rcon;
    wire [31:0] next_w1 = w1 ^ next_w0;
    wire [31:0] next_w2 = w2 ^ next_w1;
    wire [31:0] next_w3 = w3 ^ next_w2;
    wire [127:0] next_key = {next_w0, next_w1, next_w2, next_w3};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            key_ready <= 1'b0;
            round_idx <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    key_ready <= 1'b0;
                    if (start_exp) begin
                        key_mem[0] <= cipher_key;
                        round_idx  <= 4'd1;
                        state      <= CALC;
                    end
                end
                CALC: begin
                    key_mem[round_idx] <= next_key;
                    if (round_idx == 4'd10) begin
                        state <= DONE;
                    end else begin
                        round_idx <= round_idx + 1'b1;
                    end
                end
                DONE: begin
                    key_ready <= 1'b1;
                    if (!start_exp) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    genvar i;
    generate
        for (i = 0; i < 11; i = i + 1) begin : pack_keys
            assign round_keys_flat[128*i +: 128] = key_mem[i];
        end
    endgenerate

endmodule