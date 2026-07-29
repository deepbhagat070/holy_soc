`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: fifo_mem
//
// FIX APPLIED: read port changed from registered (1-cycle-delayed)
// to combinational (asynchronous). 
//
// Why: uart_system.v uses the SAME signal (start_transfer) as both
// this module's r_en AND urat_txt's tx_start in the same cycle.
// urat_txt latches `data_in` (=rdata) on the cycle tx_start fires --
// but with a REGISTERED read port, rdata doesn't reflect the new
// address until ONE CYCLE LATER. That mismatch meant urat_txt was
// always capturing the previous (stale, or on the very first byte,
// uninitialized/X) value instead of the byte that was just popped.
//
// A combinational read makes rdata reflect fifo_ram[raddr]
// immediately, matching what the rest of the design already assumes.
// For a small 16-entry FIFO this is a perfectly normal choice (no
// BRAM inference benefit is being given up that matters here).
//////////////////////////////////////////////////////////////////////////////////

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

    // Zero-init for simulation cleanliness (avoids X on power-up
    // before the first write ever happens).
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

    // FIX: combinational (asynchronous) read -- was registered,
    // causing a 1-cycle mismatch with how urat_txt consumes rdata.
    assign rdata = fifo_ram[raddr];

endmodule