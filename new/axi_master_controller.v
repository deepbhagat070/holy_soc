`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2026 16:22:28
// Design Name: 
// Module Name: axi_master_controller
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
////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module axi_master_controller (
    input  wire        clk,
    input  wire        rstn,

    // CPU Native Interface
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_write,
    input  wire        cpu_read,
    output reg  [31:0] cpu_rdata,
    output reg         stall_pipeline,

    // AXI4-Lite Master Interface
    output reg  [31:0] m_axi_awaddr,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
    
    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
    
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,
    
    output reg  [31:0] m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,
    
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);

    localparam IDLE       = 3'b000;
    localparam W_DATA     = 3'b001;
    localparam W_RESP     = 3'b010;
    localparam R_ADDR     = 3'b011;
    localparam R_DATA     = 3'b100;
    localparam CLEANUP    = 3'b101;

    reg [2:0] state;
    reg aw_done;
    reg w_done;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state          <= IDLE;
            stall_pipeline <= 1'b0;
            cpu_rdata      <= 32'b0;
            m_axi_awaddr   <= 32'b0;
            m_axi_awvalid  <= 1'b0;
            m_axi_wdata    <= 32'b0;
            m_axi_wstrb    <= 4'b1111;
            m_axi_wvalid   <= 1'b0;
            m_axi_bready   <= 1'b0;
            m_axi_araddr   <= 32'b0;
            m_axi_arvalid  <= 1'b0;
            m_axi_rready   <= 1'b0;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    stall_pipeline <= 1'b0;
                    m_axi_awvalid  <= 1'b0;
                    m_axi_wvalid   <= 1'b0;
                    m_axi_bready   <= 1'b0;
                    m_axi_arvalid  <= 1'b0;
                    m_axi_rready   <= 1'b0;
                    aw_done        <= 1'b0;
                    w_done         <= 1'b0;

                    if (cpu_write) begin
                        state          <= W_DATA;
                        stall_pipeline <= 1'b1;
                        m_axi_awaddr   <= cpu_addr;
                        m_axi_wdata    <= cpu_wdata;
                        m_axi_awvalid  <= 1'b1;
                        m_axi_wvalid   <= 1'b1;
                    end else if (cpu_read) begin
                        state          <= R_ADDR;
                        stall_pipeline <= 1'b1;
                        m_axi_araddr   <= cpu_addr;
                        m_axi_arvalid  <= 1'b1;
                    end
                end

                W_DATA: begin
                    if (m_axi_awready) m_axi_awvalid <= 1'b0;
                    if (m_axi_wready)  m_axi_wvalid  <= 1'b0;

                    if ((m_axi_awready || !m_axi_awvalid) && (m_axi_wready || !m_axi_wvalid)) begin
                        state        <= W_RESP;
                        m_axi_bready <= 1'b1;
                    end
                end

                W_RESP: begin
                    if (m_axi_bvalid) begin
                        m_axi_bready   <= 1'b0;
                        stall_pipeline <= 1'b0;
                        state          <= CLEANUP;
                    end
                end

                R_ADDR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        state         <= R_DATA;
                        m_axi_rready  <= 1'b1;
                    end
                end

                R_DATA: begin
                    if (m_axi_rvalid) begin
                        cpu_rdata     <= m_axi_rdata;
                        stall_pipeline <= 1'b0;
                        m_axi_rready  <= 1'b0;
                        state         <= CLEANUP;
                    end
                end

                CLEANUP: begin
                    stall_pipeline <= 1'b0;
                    state          <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule