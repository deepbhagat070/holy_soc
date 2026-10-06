`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        rx_done
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;
    localparam CLEANUP = 3'b100;

    reg [2:0]  state;
    reg [9:0]  clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  data_reg;
    reg        rx_sync, rx_r;

    // Double Flop Synchronizer for RX
    always @(posedge clk) begin
        if (rst) begin
            rx_sync <= 1'b1;
            rx_r    <= 1'b1;
        end else begin
            rx_sync <= rx;
            rx_r    <= rx_sync;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_reg  <= 0;
            data_out  <= 0;
            rx_done   <= 0;
        end else begin
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_r == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx_r == 1'b0) begin // Confirm it's still low
                            clk_count <= 0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        data_reg[bit_index] <= rx_r;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        data_out <= data_reg;
                        rx_done  <= 1'b1;
                        state    <= CLEANUP;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                CLEANUP: begin
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
