`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 10:55:43
// Design Name: 
// Module Name: uart_system
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

module uart_system (
    input clk_100mhz,
    input rst_100mhz,
    input w_en,
    input [7:0] wdata,
    output fifo_full,
    
   
    output tx
);

    wire fifo_empty;
    wire [7:0] fifo_rdata;
    wire tx_tick;
    wire tx_done;
    
    reg uart_busy;
    
    wire start_transfer = (~fifo_empty & ~uart_busy);

    async_fifo my_bridge (
        .wclk(clk_100mhz),
        .wrst(rst_100mhz),
        .w_en(w_en),
        .wdata(wdata),
        .full(fifo_full),
        
        .rclk(clk_100mhz),  
        .rrst(rst_100mhz),
        .r_en(start_transfer), 
        .rdata(fifo_rdata),
        .empty(fifo_empty)
    );

    
    baud_generator #(
        .Max_count(868)
    ) my_baud (
        .clk(clk_100mhz),
        .rst(rst_100mhz),
        .tx_tick(tx_tick)
    );

   
    urat_txt my_tx (
        .clk(clk_100mhz),
        .rst(rst_100mhz),
        .tx_tick(tx_tick),
        .tx_start(start_transfer),
        .data_in(fifo_rdata),    
        .tx(tx),
        .tx_done(tx_done)
    );

   
    always @(posedge clk_100mhz) begin
        if (rst_100mhz) begin
            uart_busy <= 1'b0;
        end else begin
            if (start_transfer) begin
                uart_busy <= 1'b1; 
            end else if (tx_done) begin
                uart_busy <= 1'b0;
            end
        end
    end

endmodule
