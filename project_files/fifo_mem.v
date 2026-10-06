`timescale 1ns / 1ps

module fifo_mem(
    input wclk,
    input w_en,
    input [3:0] waddr,
    input [7:0] wdata,
    
    input rclk,
    input r_en,
    input [3:0] raddr,
    
    output [7:0] rdata

    );
    
    reg [7:0] fifo_ram [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            fifo_ram[i] = 8'b0;
        end
    end
    
    always @(posedge wclk) begin
        if(w_en) begin 
            fifo_ram [waddr] <= wdata;
        end
    end

    assign rdata = fifo_ram[raddr];

endmodule