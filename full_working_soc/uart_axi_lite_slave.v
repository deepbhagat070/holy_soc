`timescale 1ns / 1ps

module uart_axi_lite_slave (
    input  wire        aclk,
    input  wire        aresetn,

    // AXI Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    // AXI Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    // AXI Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    // AXI Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // UART Output
    output wire        tx
);

    wire       fifo_full;
    reg        uart_w_en;
    reg  [7:0] uart_wdata;

    uart_system my_uart (
        .clk_100mhz (aclk),
        .rst_100mhz (~aresetn),
        .w_en       (uart_w_en),
        .wdata      (uart_wdata),
        .fifo_full  (fifo_full),
        .tx         (tx)
    );

    // -------------------------------------------------------------------------
    // Write Channel Logic (Decoupled Handshake)
    // -------------------------------------------------------------------------
    reg [31:0] awaddr_reg;
    reg        aw_en;
    reg [31:0] wdata_reg;
    reg        w_en;

    // Ready logic: Latch is empty, not waiting on BVALID, and UART FIFO has space
    assign s_axi_awready = ~aw_en && ~s_axi_bvalid;
    assign s_axi_wready  = ~w_en  && ~s_axi_bvalid && ~fifo_full;

    always @(posedge aclk) begin
        if (~aresetn) begin
            aw_en <= 1'b0;
            awaddr_reg <= 32'b0;
        end else if (s_axi_awvalid && s_axi_awready) begin
            aw_en <= 1'b1;
            awaddr_reg <= s_axi_awaddr;
        end else if (s_axi_bvalid && s_axi_bready) begin
            aw_en <= 1'b0;
        end
    end

    always @(posedge aclk) begin
        if (~aresetn) begin
            w_en <= 1'b0;
            wdata_reg <= 32'b0;
        end else if (s_axi_wvalid && s_axi_wready) begin
            w_en <= 1'b1;
            wdata_reg <= s_axi_wdata;
        end else if (s_axi_bvalid && s_axi_bready) begin
            w_en <= 1'b0;
        end
    end

    wire do_write = aw_en && w_en && ~s_axi_bvalid;

    always @(posedge aclk) begin
        if (~aresetn) begin
            uart_w_en    <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            uart_wdata   <= 8'b0;
        end else begin
            uart_w_en <= 1'b0; // Default to 1-cycle pulse
            
            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                
                if (awaddr_reg[7:0] == 8'h00) begin
                    uart_w_en  <= 1'b1; 
                    uart_wdata <= wdata_reg[7:0]; // Direct map without wstrb complexity for this register
                end
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read Channel Logic (Decoupled Handshake)
    // -------------------------------------------------------------------------
    reg [31:0] araddr_reg;
    reg        ar_en;

    assign s_axi_arready = ~ar_en && ~s_axi_rvalid;

    always @(posedge aclk) begin
        if (~aresetn) begin
            ar_en <= 1'b0;
            araddr_reg <= 32'b0;
        end else if (s_axi_arvalid && s_axi_arready) begin
            ar_en <= 1'b1;
            araddr_reg <= s_axi_araddr;
        end else if (s_axi_rvalid && s_axi_rready) begin
            ar_en <= 1'b0;
        end
    end

    wire do_read = ar_en && ~s_axi_rvalid;

    always @(posedge aclk) begin
        if (~aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'b0;
        end else begin
            if (do_read) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; 
                
                if (araddr_reg[7:0] == 8'h04) begin
                    s_axi_rdata <= {31'b0, fifo_full};
                end else begin
                    s_axi_rdata <= 32'b0; 
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule