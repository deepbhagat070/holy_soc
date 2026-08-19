`timescale 1ns / 1ps

module cache_subsystem (
    input  wire        clk,
    input  wire        rst,
    input  wire        icache_flush, 
    input  wire        dcache_flush,      
    output wire        dcache_flush_done, 
    input  wire        if_req,
    input  wire [31:0] if_addr,
    output wire [31:0] if_rdata,
    output wire        if_ready,
    input  wire        mem_req,
    input  wire [3:0]  mem_wstrb,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    output wire [31:0] mem_rdata,
    output wire        mem_ready,
    output wire        sys_bus_req,
    output wire [3:0]  sys_bus_wstrb,
    output wire [31:0] sys_bus_addr,
    output wire [31:0] sys_bus_wdata,
    input  wire        sys_bus_grant,
    input  wire        sys_bus_ready,
    input  wire [31:0] sys_bus_rdata
);

    wire i_bus_req, i_bus_grant;
    wire [31:0] i_bus_addr;
    
    wire d_bus_req, d_bus_grant;
    wire [31:0] d_bus_addr, d_bus_wdata;
    wire [3:0]  d_bus_wstrb;

    wire shared_bus_ready;
    wire [31:0] shared_bus_rdata;

    icache_controller icache (
        .clk(clk),
        .rst(rst), 
        .flush(icache_flush),
        .cpu_req(if_req), 
        .cpu_addr(if_addr), 
        .cpu_rdata(if_rdata), 
        .cpu_ready(if_ready),
        .bus_req(i_bus_req), 
        .bus_addr(i_bus_addr), 
        .bus_grant(i_bus_grant),
        .bus_ready(shared_bus_ready), 
        .bus_rdata(shared_bus_rdata)
    );

    dcache_controller dcache (
        .clk(clk), 
        .rst(rst),
        .flush(dcache_flush),          
        .flush_done(dcache_flush_done), 
        .cpu_req(mem_req), 
        .cpu_wstrb(mem_wstrb), 
        .cpu_addr(mem_addr), 
        .cpu_wdata(mem_wdata),
        .cpu_rdata(mem_rdata), 
        .cpu_ready(mem_ready),
        .bus_req(d_bus_req), 
        .bus_wstrb(d_bus_wstrb), 
        .bus_addr(d_bus_addr), 
        .bus_wdata(d_bus_wdata),
        .bus_grant(d_bus_grant), 
        .bus_ready(shared_bus_ready), 
        .bus_rdata(shared_bus_rdata)
    );

    mem_arbiter arbiter (
        .clk(clk), 
        .rst(rst),
        .i_bus_req(i_bus_req), 
        .i_bus_addr(i_bus_addr), 
        .i_bus_grant(i_bus_grant),
        .d_bus_req(d_bus_req), 
        .d_bus_addr(d_bus_addr), 
        .d_bus_wdata(d_bus_wdata), 
        .d_bus_wstrb(d_bus_wstrb),
        .d_bus_grant(d_bus_grant),
        .cache_bus_ready(shared_bus_ready), 
        .cache_bus_rdata(shared_bus_rdata),
        .mem_bus_req(sys_bus_req), 
        .mem_bus_addr(sys_bus_addr), 
        .mem_bus_wdata(sys_bus_wdata), 
        .mem_bus_wstrb(sys_bus_wstrb),
        .mem_bus_grant(sys_bus_grant), 
        .mem_bus_ready(sys_bus_ready), 
        .mem_bus_rdata(sys_bus_rdata)
    );
endmodule