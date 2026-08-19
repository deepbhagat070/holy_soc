`timescale 1ns / 1ps

module async_fifo (

    input wclk,
    input wrst,
    input w_en,
    input [7:0] wdata,
    output full,
    

    input rclk,
    input rrst,
    input r_en,
    output [7:0] rdata,
    output empty
);

   
    wire [3:0] waddr, raddr;           
    wire [4:0] wptr_gray, rptr_gray;   
    wire [4:0] wptr_sync, rptr_sync;   

   
    assign empty = (rptr_gray == wptr_sync);
    assign full = (wptr_gray == {~rptr_sync[4:3], rptr_sync[2:0]});

    
     fifo_mem my_fifo_mem (
        .wclk(wclk),
        .w_en(w_en & ~full),   
        .waddr(waddr),
        .wdata(wdata),
        
        .rclk(rclk),
        .r_en(r_en & ~empty), 
        .raddr(raddr),
        .rdata(rdata)
    );

    wptr_handler my_wptr_handler(
        .wclk(wclk),
        .rst(wrst),
        .w_en(w_en & ~full),   
        .wptr(wptr_gray),
        .waddr(waddr)
    );

    
     rptr_handler my_rptr_handler(
        .rclk(rclk),
        .rst(rrst),
        .r_en(r_en & ~empty),  
        .rptr(rptr_gray),
        .raddr(raddr)
    );

    
    synchronizer sync_w2r (
        .clk(rclk),
        .rst(rrst),
        .d_in(wptr_gray),
        .d_out(wptr_sync)
    );

    synchronizer sync_r2w (
        .clk(wclk),
        .rst(wrst),
        .d_in(rptr_gray),
        .d_out(rptr_sync)
    );

endmodule
