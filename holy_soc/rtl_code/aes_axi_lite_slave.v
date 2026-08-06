`timescale 1ns / 1ps

module aes_axi_lite_slave (
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
    input  wire        s_axi_rready
);

    reg [31:0] axi_awaddr;
    reg [31:0] axi_araddr;
    reg        aw_en; 
    reg        w_en;  
    reg        ar_en;

    reg  [127:0] key_reg;
    reg  [127:0] pt_reg;
    reg          start_pulse;
    reg          aes_done_latched;

    wire [127:0] ciphertext;
    wire         aes_done;

    aes_core my_aes (
        .clk       (aclk),
        .reset     (~aresetn), 
        .start     (start_pulse),
        .plaintext (pt_reg),
        .round_key (key_reg),
        .ciphertext(ciphertext),
        .done      (aes_done)
    );

    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            aes_done_latched <= 1'b0;
        end else begin
            if (aes_done) begin
                aes_done_latched <= 1'b1;
            end 
            else if (start_pulse) begin
                aes_done_latched <= 1'b0;
            end 

            else if (ar_en && s_axi_rvalid && s_axi_rready && (axi_araddr[7:0] == 8'h24)) begin
                aes_done_latched <= 1'b0;
            end
        end
    end

    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            s_axi_awready <= 1'b1;
            aw_en         <= 1'b0;
            axi_awaddr    <= 32'b0;   
        end else begin
            if (s_axi_awready && s_axi_awvalid) begin
                axi_awaddr    <= s_axi_awaddr;
                aw_en         <= 1'b1;
                s_axi_awready <= 1'b0;
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                 aw_en         <= 1'b0;
                 s_axi_awready <= 1'b1;
            end
        end
    end

    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            w_en         <= 1'b0;
            s_axi_wready <= 1'b0;
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin 
                w_en         <= 1'b1;
                s_axi_wready <= 1'b0; 
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                w_en <= 1'b0;
            end
            else if (~w_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    always @(posedge aclk) begin
        if (aresetn == 1'b0) begin
            start_pulse  <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            key_reg      <= 128'b0;
            pt_reg       <= 128'b0;
        end else begin
            start_pulse <= 1'b0;

            if (aw_en && w_en && !s_axi_bvalid) begin
                case (axi_awaddr[7:0])
                    8'h00: key_reg[127:96] <= s_axi_wdata;
                    8'h04: key_reg[95:64]  <= s_axi_wdata;
                    8'h08: key_reg[63:32]  <= s_axi_wdata;
                    8'h0C: key_reg[31:0]   <= s_axi_wdata;
                    8'h10: pt_reg[127:96]  <= s_axi_wdata;
                    8'h14: pt_reg[95:64]   <= s_axi_wdata;
                    8'h18: pt_reg[63:32]   <= s_axi_wdata;
                    8'h1C: pt_reg[31:0]    <= s_axi_wdata;
                    
                    8'h20: start_pulse     <= s_axi_wdata[0];
                endcase
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
                case (axi_araddr[7:0])
                    8'h24: s_axi_rdata <= {30'b0, aes_done_latched, 1'b0}; 
                    8'h28: s_axi_rdata <= ciphertext[127:96];
                    8'h2C: s_axi_rdata <= ciphertext[95:64];
                    8'h30: s_axi_rdata <= ciphertext[63:32];
                    8'h34: s_axi_rdata <= ciphertext[31:0];
                    default: s_axi_rdata <= 32'b0; 
                endcase
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule