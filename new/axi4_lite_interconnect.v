`timescale 1ns / 1ps

module axi4_lite_interconnect (

    input  wire [31:0] m_awaddr, 
    input wire m_awvalid, 
    output wire m_awready,
    
    input  wire [31:0] m_wdata, 
    input wire [3:0] m_wstrb, 
    input wire m_wvalid, 
    output wire m_wready,
    
    output wire [1:0]  m_bresp, 
    output wire m_bvalid, 
    input wire m_bready,
    
    input  wire [31:0] m_araddr, 
    input wire m_arvalid, 
    output wire m_arready,
    
    output wire [31:0] m_rdata, 
    output wire [1:0] m_rresp, 
    output wire m_rvalid, 
    input wire m_rready,

    output wire [31:0] s0_awaddr, 
    output wire s0_awvalid, 
    input wire s0_awready,
    
    output wire [31:0] s0_wdata, 
    output wire [3:0] s0_wstrb, 
    output wire s0_wvalid, 
    input wire s0_wready,
    
    input  wire [1:0]  s0_bresp, 
    input wire s0_bvalid, 
    output wire s0_bready,
    
    output wire [31:0] s0_araddr, 
    output wire s0_arvalid, 
    input wire s0_arready,
    
    input  wire [31:0] s0_rdata, 
    input wire [1:0] s0_rresp, 
    input wire s0_rvalid, 
    output wire s0_rready,

    output wire [31:0] s1_awaddr, 
    output wire s1_awvalid, 
    input wire s1_awready,
    
    output wire [31:0] s1_wdata, 
    output wire [3:0] s1_wstrb, 
    output wire s1_wvalid, 
    input wire s1_wready,
    
    input  wire [1:0]  s1_bresp, 
    input wire s1_bvalid, 
    output wire s1_bready,
    
    output wire [31:0] s1_araddr, 
    output wire s1_arvalid, 
    input wire s1_arready,
    
    input  wire [31:0] s1_rdata, 
    input wire [1:0] s1_rresp, 
    input wire s1_rvalid, 
    output wire s1_rready
);

    wire sel_s0_w = (m_awaddr[29:28] == 2'b01);
    wire sel_s1_w = (m_awaddr[29:28] == 2'b10);
    wire err_w    = ~(sel_s0_w | sel_s1_w);

    wire sel_s0_r = (m_araddr[29:28] == 2'b01);
    wire sel_s1_r = (m_araddr[29:28] == 2'b10);
    wire err_r    = ~(sel_s0_r | sel_s1_r);

    assign s0_awaddr  = m_awaddr;
    assign s0_awvalid = m_awvalid & sel_s0_w;
    assign s0_wdata   = m_wdata;
    assign s0_wstrb   = m_wstrb;
    assign s0_wvalid  = m_wvalid & sel_s0_w;
    assign s0_bready  = m_bready & sel_s0_w;
    
    assign s1_awaddr  = m_awaddr;
    assign s1_awvalid = m_awvalid & sel_s1_w;
    assign s1_wdata   = m_wdata;
    assign s1_wstrb   = m_wstrb;
    assign s1_wvalid  = m_wvalid & sel_s1_w;
    assign s1_bready  = m_bready & sel_s1_w;

    assign s0_araddr  = m_araddr;
    assign s0_arvalid = m_arvalid & sel_s0_r;
    assign s0_rready  = m_rready & sel_s0_r;

    assign s1_araddr  = m_araddr;
    assign s1_arvalid = m_arvalid & sel_s1_r;
    assign s1_rready  = m_rready & sel_s1_r;


    assign m_awready = sel_s0_w ? s0_awready : sel_s1_w ? s1_awready : 1'b1;
    assign m_wready  = sel_s0_w ? s0_wready  : sel_s1_w ? s1_wready  : 1'b1;
    assign m_bvalid  = sel_s0_w ? s0_bvalid  : sel_s1_w ? s1_bvalid  : (m_awvalid & m_wvalid); 
    assign m_bresp   = sel_s0_w ? s0_bresp   : sel_s1_w ? s1_bresp   : 2'b11; 

    assign m_arready = sel_s0_r ? s0_arready : sel_s1_r ? s1_arready : 1'b1;
    assign m_rvalid  = sel_s0_r ? s0_rvalid  : sel_s1_r ? s1_rvalid  : m_arvalid; 
    assign m_rdata   = sel_s0_r ? s0_rdata   : sel_s1_r ? s1_rdata   : 32'hDEADBEEF;
    assign m_rresp   = sel_s0_r ? s0_rresp   : sel_s1_r ? s1_rresp   : 2'b11; 
    
endmodule