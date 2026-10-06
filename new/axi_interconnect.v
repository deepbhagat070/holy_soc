`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2026 16:31:12
// Design Name: 
// Module Name: axi_interconnect
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

`timescale 1ns / 1ps

module axi_interconnect (
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    output wire [31:0] m0_axi_awaddr,
    output wire        m0_axi_awvalid,
    input  wire        m0_axi_awready,
    output wire [31:0] m0_axi_wdata,
    output wire [3:0]  m0_axi_wstrb,
    output wire        m0_axi_wvalid,
    input  wire        m0_axi_wready,
    input  wire [1:0]  m0_axi_bresp,
    input  wire        m0_axi_bvalid,
    output wire        m0_axi_bready,
    output wire [31:0] m0_axi_araddr,
    output wire        m0_axi_arvalid,
    input  wire        m0_axi_arready,
    input  wire [31:0] m0_axi_rdata,
    input  wire [1:0]  m0_axi_rresp,
    input  wire        m0_axi_rvalid,
    output wire        m0_axi_rready,

    output wire [31:0] m1_axi_awaddr,
    output wire        m1_axi_awvalid,
    input  wire        m1_axi_awready,
    output wire [31:0] m1_axi_wdata,
    output wire [3:0]  m1_axi_wstrb,
    output wire        m1_axi_wvalid,
    input  wire        m1_axi_wready,
    input  wire [1:0]  m1_axi_bresp,
    input  wire        m1_axi_bvalid,
    output wire        m1_axi_bready,
    output wire [31:0] m1_axi_araddr,
    output wire        m1_axi_arvalid,
    input  wire        m1_axi_arready,
    input  wire [31:0] m1_axi_rdata,
    input  wire [1:0]  m1_axi_rresp,
    input  wire        m1_axi_rvalid,
    output wire        m1_axi_rready,

    output wire [31:0] m2_axi_awaddr,
    output wire        m2_axi_awvalid,
    input  wire        m2_axi_awready,
    output wire [31:0] m2_axi_wdata,
    output wire [3:0]  m2_axi_wstrb,
    output wire        m2_axi_wvalid,
    input  wire        m2_axi_wready,
    input  wire [1:0]  m2_axi_bresp,
    input  wire        m2_axi_bvalid,
    output wire        m2_axi_bready,
    output wire [31:0] m2_axi_araddr,
    output wire        m2_axi_arvalid,
    input  wire        m2_axi_arready,
    input  wire [31:0] m2_axi_rdata,
    input  wire [1:0]  m2_axi_rresp,
    input  wire        m2_axi_rvalid,
    output wire        m2_axi_rready
);

    // 1. Separate Write Addresses
    wire aw_ram  = (s_axi_awaddr[31:28] == 4'h2);
    wire aw_uart = (s_axi_awaddr[31:28] == 4'h4);
    wire aw_aes  = (s_axi_awaddr[31:28] == 4'h5);

    // 2. Separate Read Addresses
    wire ar_ram  = (s_axi_araddr[31:28] == 4'h2);
    wire ar_uart = (s_axi_araddr[31:28] == 4'h4);
    wire ar_aes  = (s_axi_araddr[31:28] == 4'h5);

    assign m0_axi_awaddr = s_axi_awaddr;
    assign m1_axi_awaddr = s_axi_awaddr;
    assign m2_axi_awaddr = s_axi_awaddr;

    // 3. Route Write Valids based ONLY on Write Addresses
    assign m0_axi_awvalid = s_axi_awvalid & aw_ram;
    assign m1_axi_awvalid = s_axi_awvalid & aw_aes;
    assign m2_axi_awvalid = s_axi_awvalid & aw_uart;

    assign m0_axi_wdata = s_axi_wdata;
    assign m1_axi_wdata = s_axi_wdata;
    assign m2_axi_wdata = s_axi_wdata;
    
    assign m0_axi_wstrb = s_axi_wstrb;
    assign m1_axi_wstrb = s_axi_wstrb;
    assign m2_axi_wstrb = s_axi_wstrb;

    assign m0_axi_wvalid = s_axi_wvalid & aw_ram;
    assign m1_axi_wvalid = s_axi_wvalid & aw_aes;
    assign m2_axi_wvalid = s_axi_wvalid & aw_uart;

    // 4. Route Write Readys
    assign s_axi_awready = (aw_ram & m0_axi_awready) | (aw_aes & m1_axi_awready) | (aw_uart & m2_axi_awready);
    assign s_axi_wready  = (aw_ram & m0_axi_wready)  | (aw_aes & m1_axi_wready)  | (aw_uart & m2_axi_wready);

    assign m0_axi_bready = s_axi_bready;
    assign m1_axi_bready = s_axi_bready;
    assign m2_axi_bready = s_axi_bready;

    assign s_axi_bvalid = m0_axi_bvalid | m1_axi_bvalid | m2_axi_bvalid;
    assign s_axi_bresp  = (m0_axi_bvalid ? m0_axi_bresp : 2'b00) | 
                          (m1_axi_bvalid ? m1_axi_bresp : 2'b00) | 
                          (m2_axi_bvalid ? m2_axi_bresp : 2'b00);

    assign m0_axi_araddr = s_axi_araddr;
    assign m1_axi_araddr = s_axi_araddr;
    assign m2_axi_araddr = s_axi_araddr;

    // 5. Route Read Valids based ONLY on Read Addresses
    assign m0_axi_arvalid = s_axi_arvalid & ar_ram;
    assign m1_axi_arvalid = s_axi_arvalid & ar_aes;
    assign m2_axi_arvalid = s_axi_arvalid & ar_uart;

    // 6. Route Read Readys
    assign s_axi_arready = (ar_ram & m0_axi_arready) | (ar_aes & m1_axi_arready) | (ar_uart & m2_axi_arready);

    assign m0_axi_rready = s_axi_rready;
    assign m1_axi_rready = s_axi_rready;
    assign m2_axi_rready = s_axi_rready;

    assign s_axi_rvalid = m0_axi_rvalid | m1_axi_rvalid | m2_axi_rvalid;
    
    assign s_axi_rdata = (m0_axi_rvalid ? m0_axi_rdata : 32'b0) | 
                         (m1_axi_rvalid ? m1_axi_rdata : 32'b0) | 
                         (m2_axi_rvalid ? m2_axi_rdata : 32'b0);

    assign s_axi_rresp = (m0_axi_rvalid ? m0_axi_rresp : 2'b00) | 
                         (m1_axi_rvalid ? m1_axi_rresp : 2'b00) | 
                         (m2_axi_rvalid ? m2_axi_rresp : 2'b00);

endmodule