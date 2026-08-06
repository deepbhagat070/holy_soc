`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2026 12:18:41
// Design Name: 
// Module Name: axi_ram
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


module axi_ram(
    input clk,
    input rstn,
    
    input [31:0] s_axi_awaddr,
    input s_axi_awvalid,
    output reg s_axi_awready,
    
    input [31:0] s_axi_wdata,
    input [3:0] s_axi_wstrb,
    input s_axi_wvalid,
    output reg s_axi_wready,
    
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input s_axi_bready,
    
    input [31:0] s_axi_araddr,
    input s_axi_arvalid,
    output reg s_axi_arready,
    
    output reg [31:0] s_axi_rdata,
    output reg s_axi_rvalid,
    output reg [1:0] s_axi_rresp,
    input s_axi_rready
    

    );
    
    reg [31:0] mem [0:255];
    
    reg [31:0] awaddr_reg;
    reg aw_en;

  
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
        end else begin
            // 1. Handshake: Accept Address
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                awaddr_reg    <= s_axi_awaddr;
                aw_en         <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // 2. Perform the Write
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                // AXI addresses are byte-aligned (0, 4, 8). Divide by 4 to get word index.
                mem[(awaddr_reg & 32'h0000FFFF) >> 2] <= s_axi_wdata;
                s_axi_bvalid <= 1'b1; // Tell CPU the write is done
            end

            // 3. Clear Response when CPU acknowledges (bready)
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end
        end
    end

    // ==========================================
    // AXI READ LOGIC (AR, R Channels)
    // ==========================================
    reg [31:0] araddr_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00; // 00 = OKAY
        end else begin
            // 1. Handshake: Accept Read Address
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // 2. Perform the Read and assert rvalid
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rdata  <= mem[(araddr_reg & 32'h0000FFFF) >> 2];
                s_axi_rvalid <= 1'b1;
            end 
            // 3. Clear when CPU acknowledges (rready)
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
