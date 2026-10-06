`timescale 1ns / 1ps

module uart_system (
    input  wire       clk_100mhz,
    input  wire       rst_100mhz,
    
    // TX Interface
    input  wire       w_en,
    input  wire [7:0] wdata,
    output wire       fifo_full,
    output wire       tx,
    
    // RX Interface
    input  wire       r_en,
    output wire [7:0] rx_rdata,
    output wire       rx_empty,
    input  wire       rx
);

    wire tx_fifo_empty;
    wire [7:0] tx_fifo_rdata;
    wire tx_tick;
    wire tx_done;
    
    reg uart_busy;
    
    wire start_transfer = (~tx_fifo_empty & ~uart_busy);

    async_fifo tx_fifo_inst (
        .wclk(clk_100mhz),
        .wrst(rst_100mhz),
        .w_en(w_en),
        .wdata(wdata),
        .full(fifo_full),
        
        .rclk(clk_100mhz),  
        .rrst(rst_100mhz),
        .r_en(start_transfer), 
        .rdata(tx_fifo_rdata),
        .empty(tx_fifo_empty)
    );

    wire rx_done;
    wire [7:0] rx_data_out;
    wire rx_fifo_full;

    async_fifo rx_fifo_inst (
        .wclk(clk_100mhz),
        .wrst(rst_100mhz),
        .w_en(rx_done),
        .wdata(rx_data_out),
        .full(rx_fifo_full),
        
        .rclk(clk_100mhz),  
        .rrst(rst_100mhz),
        .r_en(r_en), 
        .rdata(rx_rdata),
        .empty(rx_empty)
    );

    uart_rx #(
        .CLKS_PER_BIT(868)
    ) my_rx (
        .clk(clk_100mhz),
        .rst(rst_100mhz),
        .rx(rx),
        .data_out(rx_data_out),
        .rx_done(rx_done)
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
        .data_in(tx_fifo_rdata),    
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
