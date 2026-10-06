`timescale 1ns / 1ps

module axi_uart (
    input  wire        clk,
    input  wire        rstn,
    
    // Only TX pin needed for your module
    output wire        tx,

    // AXI4-Lite Slave Interface
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers to drive your uart_system
    reg  [7:0] wdata_reg;
    reg        w_en_reg;
    wire       fifo_full;

    // AXI State Machine Registers
    reg [31:0] awaddr_reg;
    reg        aw_en;
    reg [31:0] araddr_reg;

    // INSTANTIATE YOUR EXACT MODULE HERE
    uart_system u_uart (
        .clk_100mhz(clk),
        .rst_100mhz(~rstn), // INVERT the AXI active-low reset to match your active-high reset
        .w_en(w_en_reg),
        .wdata(wdata_reg),
        .fifo_full(fifo_full),
        .tx(tx)
    );

    // -----------------------------------------------------------
    // WRITE CHANNEL (CPU -> UART FIFO)
    // -----------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
            
            w_en_reg      <= 1'b0;
            wdata_reg     <= 8'b0;
        end else begin
            // 1. Handshake Initiation
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                awaddr_reg    <= s_axi_awaddr;
                aw_en         <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // Auto-reset the Write Enable so it only pulses for 1 cycle!
            w_en_reg <= 1'b0;

            // 2. Physical Write Switchboard
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (awaddr_reg[7:0])
                    8'h00: begin
                        wdata_reg <= s_axi_wdata[7:0]; // Grab the character
                        w_en_reg  <= 1'b1;             // Pulse w_en to push into FIFO
                    end
                endcase
                s_axi_bvalid <= 1'b1;
            end

            // 3. Clear Response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end
        end
    end

    // -----------------------------------------------------------
    // READ CHANNEL (CPU reads FIFO Status)
    // -----------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'b0;
        end else begin
            // 1. Handshake Initiation
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // 2. Physical Read Switchboard
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case (araddr_reg[7:0])
                    // Address 0x04: Status Register (Bit 0 tells CPU if FIFO is full)
                    8'h04: s_axi_rdata <= {31'b0, fifo_full};
                    default: s_axi_rdata <= 32'b0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule