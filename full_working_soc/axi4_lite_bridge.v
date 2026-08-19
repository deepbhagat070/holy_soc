`timescale 1ns / 1ps

module axi4_lite_bridge (
    input  wire        clk,
    input  wire        rst,

    input  wire        sys_req,
    input  wire [31:0] sys_addr,
    input  wire [31:0] sys_wdata,
    input  wire [3:0]  sys_wstrb,
    output reg         sys_ready,
    output reg  [31:0] sys_rdata,

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

    localparam IDLE   = 3'd0;
    localparam WISSUE = 3'd1;
    localparam WRESP  = 3'd2;
    localparam RISSUE = 3'd3;
    localparam RRESP  = 3'd4;

    reg [2:0] state, next_state;
    wire is_write = (sys_wstrb != 4'b0000);

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (sys_req)
                    next_state = is_write ? WISSUE : RISSUE;
            end
            WISSUE: begin
                if (!m_axi_awvalid && !m_axi_wvalid)
                    next_state = WRESP;
            end
            WRESP: begin
                if (!m_axi_bready && !sys_req) next_state = IDLE;
            end
            RISSUE: begin
                if (m_axi_arready) next_state = RRESP;
            end
            RRESP: begin
                if (!m_axi_rready && !sys_req) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid  <= 1'b0;
            m_axi_bready  <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b0;
            sys_ready     <= 1'b0;
            sys_rdata     <= 32'b0;
        end else begin
            sys_ready <= 1'b0; 

            case (state)
                IDLE: begin
                    if (sys_req) begin
                        if (is_write) begin
                            m_axi_awaddr  <= sys_addr;
                            m_axi_wdata   <= sys_wdata;
                            m_axi_wstrb   <= sys_wstrb;
                            m_axi_awvalid <= 1'b1;
                            m_axi_wvalid  <= 1'b1;
                            m_axi_bready  <= 1'b1;
                        end else begin
                            m_axi_araddr  <= sys_addr;
                            m_axi_arvalid <= 1'b1;
                            m_axi_rready  <= 1'b1;
                        end
                    end
                end

                WISSUE: begin
                    if (m_axi_awready) m_axi_awvalid <= 1'b0;
                    if (m_axi_wready)  m_axi_wvalid  <= 1'b0;
                end

                WRESP: begin
                    if (m_axi_bvalid) begin
                        m_axi_bready <= 1'b1;
                        sys_ready    <= 1'b1; 
                        
                    end else begin
                        m_axi_bready <= 1'b0;
                    end
                end

                RISSUE: begin
                    if (m_axi_arready) m_axi_arvalid <= 1'b0;
                end

                RRESP: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        sys_rdata    <= m_axi_rdata;
                        m_axi_rready <= 1'b0;
                        sys_ready    <= 1'b1; 
                    end
                end

                default: begin end
            endcase
        end
    end
endmodule