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
    

    assign ready = !wait_state && !(sel && wr_en && fifo_full);
    
    always @(posedge clk) begin
        if(rst) begin
            wait_state <= 1'b0;
            uart_w_en  <= 1'b0;
            uart_wdata <= 8'b0;
        end else begin
            if (wait_state) begin                
                uart_w_en  <= 1'b0;
                wait_state <= 1'b0;
                
            end else if (sel && wr_en && !fifo_full) begin
                uart_wdata <= wdata[7:0];
                uart_w_en  <= 1'b1; 
                wait_state <= 1'b1;
                
            end else begin
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