`timescale 1ns / 1ps

module fpga_top (
    input  wire clk_in,   // Usually 100MHz or 50MHz depending on board
    input  wire rst_n,    // Active low reset button
    output wire uart_tx,
    input  wire uart_rx
);

    // Clock buffering (simplified, replace with PLL/MMCM if needed)
    wire clk = clk_in; 

    // Reset synchronization and debouncing
    reg [7:0] rst_cnt = 0;
    reg       rst_sync = 1'b1;
    wire      rst = rst_sync;

    always @(posedge clk) begin
        if (!rst_n) begin
            rst_cnt  <= 0;
            rst_sync <= 1'b1;
        end else begin
            if (rst_cnt == 8'hFF) begin
                rst_sync <= 1'b0;
            end else begin
                rst_cnt <= rst_cnt + 1;
            end
        end
    end

    // Instantiate SoC
    soc_top u_soc_top (
        .clk     (clk),
        .rst     (rst),
        .ext_irq (1'b0), // Tie off external interrupts for now
        .uart_tx (uart_tx),
        .uart_rx (uart_rx)
    );

endmodule
