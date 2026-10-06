`timescale 1ns / 1ps

module uart_wrapper(
    input clk,
    input rst,
    input sel,
    input wr_en,
    input [31:0] wdata,
    input [3:0] wstrb,
    output ready,
    output tx
);
    
    reg wait_state;
    reg uart_w_en;
    reg [7:0] uart_wdata;
    wire fifo_full;
    
    // THE ULTIMATE HARDWARE FIX:
    // The CPU is only allowed to advance IF we are not in a cooldown pulse gap, 
    // AND (if it wants to write) the FIFO actually has room for it!
    assign ready = !wait_state && !(sel && wr_en && fifo_full);
    
    always @(posedge clk) begin
        if(rst) begin
            wait_state <= 1'b0;
            uart_w_en  <= 1'b0;
            uart_wdata <= 8'b0;
        end else begin
            if (wait_state) begin
                // 1. Cooldown Cycle: Drop the write enable to create a perfect falling edge.
                // Because wait_state is 1, 'ready' is 0. The CPU is safely frozen here.
                uart_w_en  <= 1'b0;
                wait_state <= 1'b0; // Unfreeze the CPU on the next clock
                
            end else if (sel && wr_en && !fifo_full) begin
                // 2. Action Cycle: We have data and room in the FIFO.
                uart_wdata <= wdata[7:0];
                uart_w_en  <= 1'b1; // Pulse the FIFO
                wait_state <= 1'b1; // Trigger the cooldown cycle to prevent back-to-back drops
                
            end else begin
                // 3. Idle Cycle: CPU isn't writing, keep the pulse low.
                uart_w_en <= 1'b0;
            end
        end
    end

    uart_system my_uart (
        .clk_100mhz(clk),
        .rst_100mhz(rst),
        .w_en(uart_w_en),
        .wdata(uart_wdata),
        .fifo_full(fifo_full),
        .tx(tx)
    );  
endmodule