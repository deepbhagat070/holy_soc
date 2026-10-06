`timescale 1ns / 1ps

module aes_wrapper (
    input         clk,
    input         rst,
    input         sel,
    input         wr_en,
    input         rd_en,
    input  [7:0]  addr,
    input  [31:0] wdata,
    output reg [31:0] rdata,
    output        ready
);

    reg [127:0] key_reg;
    reg [127:0] pt_reg;
    reg         start_pulse;
    reg         aes_done_latched; // The sticky memory flag
    
    wire [127:0] ciphertext;
    wire         aes_done;

    assign ready = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            key_reg          <= 128'b0;
            pt_reg           <= 128'b0;
            start_pulse      <= 1'b0;
            aes_done_latched <= 1'b0;
        end else begin
            start_pulse <= 1'b0; // Default: always clear the start pulse

            // 1. Catch the lightning strike! If the AES core blinks "done", hold it.
            if (aes_done) begin
                aes_done_latched <= 1'b1; 
            end
            // 2. Clear-on-Read: When the CPU successfully reads the status register, reset it!
            else if (sel && rd_en && (addr == 8'h24)) begin
                aes_done_latched <= 1'b0;
            end

            if (sel && wr_en) begin
                case (addr)
                    8'h00: key_reg[127:96] <= wdata;
                    8'h04: key_reg[95:64]  <= wdata;
                    8'h08: key_reg[63:32]  <= wdata;
                    8'h0C: key_reg[31:0]   <= wdata;

                    8'h10: pt_reg[127:96] <= wdata;
                    8'h14: pt_reg[95:64]  <= wdata;
                    8'h18: pt_reg[63:32]  <= wdata;
                    8'h1C: pt_reg[31:0]   <= wdata;
                    
                    8'h20: begin
                        start_pulse      <= wdata[0];
                        aes_done_latched <= 1'b0; // Clear the latch when starting a new encryption
                    end
                endcase
            end
        end
    end

    always @(*) begin
        rdata = 32'b0;
        
        if (sel && rd_en) begin
            case (addr)
                // CPU now reads the latched flag! Mapped to Bit 1.
                8'h24: rdata = {30'b0, aes_done_latched, 1'b0}; 
                8'h28: rdata = ciphertext[127:96];
                8'h2C: rdata = ciphertext[95:64];
                8'h30: rdata = ciphertext[63:32];
                8'h34: rdata = ciphertext[31:0];
            endcase
        end
    end
    

    aes_core my_aes (
        .clk       (clk),
        .reset     (rst),
        .start     (start_pulse),
        .plaintext (pt_reg),
        .round_key (key_reg),
        .ciphertext(ciphertext),
        .done      (aes_done)
    );

endmodule