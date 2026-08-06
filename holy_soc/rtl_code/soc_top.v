`timescale 1ns / 1ps

module soc_top (
    input  wire clk,
    input  wire rst,
    input  wire ext_irq, 
    output wire uart_tx,
    input  wire uart_rx
);

    wire [31:0] cpu_imem_addr, cpu_imem_rdata;
    wire        cpu_imem_req, cpu_imem_ready;

    wire [31:0] cpu_dmem_addr, cpu_dmem_wdata, cpu_dmem_rdata;
    wire [3:0]  cpu_dmem_wstrb;
    wire        cpu_dmem_read_en, cpu_dmem_ready;
    wire        icache_flush, dcache_flush, dcache_flush_done; 

    top_pipelined my_cpu (
        .clk               (clk),
        .rst               (rst),
        .ext_irq           (ext_irq),
        .imem_addr         (cpu_imem_addr),
        .imem_rdata        (cpu_imem_rdata),
        .imem_ready        (cpu_imem_ready),
        .imem_req          (cpu_imem_req),
        .dmem_addr         (cpu_dmem_addr),
        .dmem_wdata        (cpu_dmem_wdata),
        .dmem_wstrb        (cpu_dmem_wstrb),
        .dmem_read_en      (cpu_dmem_read_en),
        .dmem_ready        (cpu_dmem_ready),
        .dmem_rdata        (cpu_dmem_rdata),
        .icache_flush_out  (icache_flush),
        .dcache_flush_out  (dcache_flush),       
        .dcache_flush_done (dcache_flush_done)   
    );

    wire        sys_bus_req, sys_bus_grant, sys_bus_ready;
    wire [31:0] sys_bus_addr, sys_bus_wdata, sys_bus_rdata;
    wire [3:0]  sys_bus_wstrb;

    cache_subsystem l1_caches (
        .clk               (clk),
        .rst               (rst),
        .icache_flush      (icache_flush),
        .dcache_flush      (dcache_flush),       
        .dcache_flush_done (dcache_flush_done),  
        .if_req            (cpu_imem_req),
        .if_addr           (cpu_imem_addr),
        .if_rdata          (cpu_imem_rdata),
        .if_ready          (cpu_imem_ready),
        .mem_req           (cpu_dmem_read_en | (cpu_dmem_wstrb != 4'b0000)), 
        .mem_wstrb         (cpu_dmem_wstrb),
        .mem_addr          (cpu_dmem_addr),
        .mem_wdata         (cpu_dmem_wdata),
        .mem_rdata         (cpu_dmem_rdata),
        .mem_ready         (cpu_dmem_ready),
        .sys_bus_req       (sys_bus_req),
        .sys_bus_wstrb     (sys_bus_wstrb),
        .sys_bus_addr      (sys_bus_addr),
        .sys_bus_wdata     (sys_bus_wdata),
        .sys_bus_grant     (sys_bus_grant),
        .sys_bus_ready     (sys_bus_ready),
        .sys_bus_rdata     (sys_bus_rdata)
    );

    wire        sel_cached = ~sys_bus_addr[31];
    wire        sel_mmio   = sys_bus_addr[31];

    wire        ram_ready, bridge_ready;
    wire [31:0] ram_rdata, bridge_rdata;

    assign sys_bus_ready = sel_cached ? ram_ready : bridge_ready;
    assign sys_bus_rdata = sel_cached ? ram_rdata : bridge_rdata;
    assign sys_bus_grant = sys_bus_req; 

    main_memory my_ram (
        .clk           (clk),
        .rst           (rst),
        .mem_bus_req   (sys_bus_req & sel_cached),
        .mem_bus_addr  (sys_bus_addr),
        .mem_bus_wdata (sys_bus_wdata),
        .mem_bus_wstrb (sel_cached ? sys_bus_wstrb : 4'b0000),
        .mem_bus_grant (), 
        .mem_bus_ready (ram_ready),
        .mem_bus_rdata (ram_rdata)
    );

    wire [31:0] m_awaddr, m_wdata, m_araddr, m_rdata;
    wire [3:0]  m_wstrb;
    wire [1:0]  m_bresp, m_rresp;
    wire        m_awvalid, m_awready, m_wvalid, m_wready, m_bvalid, m_bready;
    wire        m_arvalid, m_arready, m_rvalid, m_rready;

    axi4_lite_bridge mmio_bridge (
        .clk           (clk), 
        .rst           (rst),
        .sys_req       (sys_bus_req & sel_mmio), 
        .sys_addr      (sys_bus_addr), 
        .sys_wdata     (sys_bus_wdata), 
        .sys_wstrb     (sys_bus_wstrb),
        .sys_ready     (bridge_ready), 
        .sys_rdata     (bridge_rdata),
        .m_axi_awaddr  (m_awaddr),  
        .m_axi_awvalid (m_awvalid), 
        .m_axi_awready (m_awready),
        .m_axi_wdata   (m_wdata),   
        .m_axi_wstrb   (m_wstrb),   
        .m_axi_wvalid  (m_wvalid),  
        .m_axi_wready  (m_wready),
        .m_axi_bresp   (m_bresp),   
        .m_axi_bvalid  (m_bvalid),  
        .m_axi_bready  (m_bready),
        .m_axi_araddr  (m_araddr),  
        .m_axi_arvalid (m_arvalid), 
        .m_axi_arready (m_arready),
        .m_axi_rdata   (m_rdata),   
        .m_axi_rresp   (m_rresp),   
        .m_axi_rvalid  (m_rvalid),  
        .m_axi_rready  (m_rready)
    );

    wire [31:0] s0_awaddr, s0_wdata, s0_araddr, s0_rdata;
    wire [3:0]  s0_wstrb;
    wire [1:0]  s0_bresp, s0_rresp;
    wire        s0_awvalid, s0_awready, s0_wvalid, s0_wready, s0_bvalid, s0_bready;
    wire        s0_arvalid, s0_arready, s0_rvalid, s0_rready;

    wire [31:0] s1_awaddr, s1_wdata, s1_araddr, s1_rdata;
    wire [3:0]  s1_wstrb;
    wire [1:0]  s1_bresp, s1_rresp;
    wire        s1_awvalid, s1_awready, s1_wvalid, s1_wready, s1_bvalid, s1_bready;
    wire        s1_arvalid, s1_arready, s1_rvalid, s1_rready;

    axi4_lite_interconnect axi_ic (
        .m_awaddr  (m_awaddr),  
        .m_awvalid (m_awvalid), 
        .m_awready (m_awready),
        .m_wdata   (m_wdata),   
        .m_wstrb   (m_wstrb),   
        .m_wvalid  (m_wvalid),  
        .m_wready  (m_wready),
        .m_bresp   (m_bresp),   
        .m_bvalid  (m_bvalid),  
        .m_bready  (m_bready),
        .m_araddr  (m_araddr),  
        .m_arvalid (m_arvalid), 
        .m_arready (m_arready),
        .m_rdata   (m_rdata),   
        .m_rresp   (m_rresp),   
        .m_rvalid  (m_rvalid),  
        .m_rready  (m_rready),
        
        .s0_awaddr (s0_awaddr), 
        .s0_awvalid(s0_awvalid), 
        .s0_awready(s0_awready),
        .s0_wdata  (s0_wdata),  
        .s0_wstrb  (s0_wstrb),   
        .s0_wvalid (s0_wvalid), 
        .s0_wready (s0_wready),
        .s0_bresp  (s0_bresp),  
        .s0_bvalid (s0_bvalid),  
        .s0_bready (s0_bready),
        .s0_araddr (s0_araddr), 
        .s0_arvalid(s0_arvalid), 
        .s0_arready(s0_arready),
        .s0_rdata  (s0_rdata),  
        .s0_rresp  (s0_rresp),   
        .s0_rvalid (s0_rvalid), 
        .s0_rready (s0_rready),

        .s1_awaddr (s1_awaddr), 
        .s1_awvalid(s1_awvalid), 
        .s1_awready(s1_awready),
        .s1_wdata  (s1_wdata),  
        .s1_wstrb  (s1_wstrb),   
        .s1_wvalid (s1_wvalid), 
        .s1_wready (s1_wready),
        .s1_bresp  (s1_bresp),  
        .s1_bvalid (s1_bvalid),  
        .s1_bready (s1_bready),
        .s1_araddr (s1_araddr), 
        .s1_arvalid(s1_arvalid), 
        .s1_arready(s1_arready),
        .s1_rdata  (s1_rdata),  
        .s1_rresp  (s1_rresp),   
        .s1_rvalid (s1_rvalid), 
        .s1_rready (s1_rready)
    );

    uart_axi_lite_slave my_uart_axi (
        .aclk          (clk),
        .aresetn       (~rst), 
        .s_axi_awaddr  (s0_awaddr),  
        .s_axi_awvalid (s0_awvalid), 
        .s_axi_awready (s0_awready),
        .s_axi_wdata   (s0_wdata),   
        .s_axi_wstrb   (s0_wstrb),   
        .s_axi_wvalid  (s0_wvalid),  
        .s_axi_wready  (s0_wready),
        .s_axi_bresp   (s0_bresp),   
        .s_axi_bvalid  (s0_bvalid),  
        .s_axi_bready  (s0_bready),
        .s_axi_araddr  (s0_araddr),  
        .s_axi_arvalid (s0_arvalid), 
        .s_axi_arready (s0_arready),
        .s_axi_rdata   (s0_rdata),   
        .s_axi_rresp   (s0_rresp),   
        .s_axi_rvalid  (s0_rvalid),  
        .s_axi_rready  (s0_rready),
        .tx            (uart_tx)
    );

    aes_axi_lite_slave my_aes_axi (
        .aclk          (clk),
        .aresetn       (~rst), 
        .s_axi_awaddr  (s1_awaddr),  
        .s_axi_awvalid (s1_awvalid), 
        .s_axi_awready (s1_awready),
        .s_axi_wdata   (s1_wdata),   
        .s_axi_wstrb   (s1_wstrb),   
        .s_axi_wvalid  (s1_wvalid),  
        .s_axi_wready  (s1_wready),
        .s_axi_bresp   (s1_bresp),   
        .s_axi_bvalid  (s1_bvalid),  
        .s_axi_bready  (s1_bready),
        .s_axi_araddr  (s1_araddr),  
        .s_axi_arvalid (s1_arvalid), 
        .s_axi_arready (s1_arready),
        .s_axi_rdata   (s1_rdata),   
        .s_axi_rresp   (s1_rresp),   
        .s_axi_rvalid  (s1_rvalid),  
        .s_axi_rready  (s1_rready)
    );

endmodule