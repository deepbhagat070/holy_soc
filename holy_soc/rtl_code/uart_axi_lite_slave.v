`timescale 1ns / 1ps

module uart_axi_lite_slave (
    input  wire        aclk,
    input  wire        aresetn,

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
    input  wire        s_axi_rready,
    
    output wire        tx
);

    
    reg [31:0] axi_awaddr;
    reg        aw_en;
    reg        w_en;
    reg        ar_en;
    reg [31:0] axi_araddr;
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

    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            s_axi_awready <= 1'b1;
            aw_en         <= 1'b0;
            axi_awaddr    <= 32'b0;   
        end else begin
            if (s_axi_awready && s_axi_awvalid) begin
                axi_awaddr <= s_axi_awaddr;
                aw_en <= 1'b1;
                s_axi_awready <=1'b0;
            end
            else if ( s_axi_bvalid && s_axi_bready) begin
                 aw_en <= 1'b0;
                 s_axi_awready <= 1'b1;
                
            end
            
        end
    end
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            w_en         <= 1'b0;
            s_axi_wready <= 1'b0;
            uart_wdata   <= 8'b0;
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin 
                w_en         <= 1'b1;
                s_axi_wready <= 1'b0; 
                case (s_axi_wstrb)
                    4'b0001 : uart_wdata <= s_axi_wdata[7:0];
                    4'b0010 : uart_wdata <= s_axi_wdata[15:8];
                    4'b0100 : uart_wdata <= s_axi_wdata[23:16];
                    4'b1000 : uart_wdata <= s_axi_wdata[31:24];
                    default : uart_wdata <= s_axi_wdata[7:0];
                endcase
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                w_en <= 1'b0;
            end
            else if (~w_en && ~fifo_full) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            uart_w_en    <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            uart_w_en <= 1'b0;
            if (aw_en && w_en && !s_axi_bvalid) begin
                if (axi_awaddr[7:0] == 8'h00) begin
                    uart_w_en <= 1'b1; 
                end
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end 
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            s_axi_arready <= 1'b0;
            ar_en         <= 1'b0;
            axi_araddr    <= 32'b0;
        end else begin
            if (~ar_en) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
    
            if (s_axi_arvalid && s_axi_arready) begin
                axi_araddr    <= s_axi_araddr;
                ar_en         <= 1'b1;
                s_axi_arready <= 1'b0;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                ar_en <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'b0;
            s_axi_rresp  <= 2'b00;
        end else begin
            if (ar_en && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; 
                if (axi_araddr[7:0] == 8'h04) begin
                    s_axi_rdata <= {31'b0, fifo_full};
                end else begin
                    s_axi_rdata <= 32'b0; 
                end
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule