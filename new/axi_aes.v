`timescale 1ns / 1ps

module axi_aes (
    input  wire        clk,
    input  wire        rstn,
    
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

    reg [31:0] key_reg [0:3];
    reg [31:0] pt_reg  [0:3];
    reg        start_reg;

    wire [127:0] aes_ct;
    wire         aes_done;

    reg [31:0] awaddr_reg;
    reg        aw_en;
    reg [31:0] araddr_reg;

    aes_core u_aes (
        .clk(clk),
        .reset(~rstn),
        .start(start_reg),
        .round_key({key_reg[0], key_reg[1], key_reg[2], key_reg[3]}),
        .plaintext({pt_reg[0], pt_reg[1], pt_reg[2], pt_reg[3]}),
        .ciphertext(aes_ct),
        .done(aes_done)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
            start_reg     <= 1'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                awaddr_reg    <= s_axi_awaddr;
                aw_en         <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            start_reg <= 1'b0;

            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (awaddr_reg[7:0])
                    8'h00: key_reg[0] <= s_axi_wdata;
                    8'h04: key_reg[1] <= s_axi_wdata;
                    8'h08: key_reg[2] <= s_axi_wdata;
                    8'h0C: key_reg[3] <= s_axi_wdata;
                    8'h10: pt_reg[0]  <= s_axi_wdata;
                    8'h14: pt_reg[1]  <= s_axi_wdata;
                    8'h18: pt_reg[2]  <= s_axi_wdata;
                    8'h1C: pt_reg[3]  <= s_axi_wdata;
                    8'h20: start_reg  <= s_axi_wdata[0];
                endcase
                s_axi_bvalid <= 1'b1;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case (araddr_reg[7:0])
                    8'h24: s_axi_rdata <= {31'b0, aes_done};
                    8'h28: s_axi_rdata <= aes_ct[127:96];
                    8'h2C: s_axi_rdata <= aes_ct[95:64];
                    8'h30: s_axi_rdata <= aes_ct[63:32];
                    8'h34: s_axi_rdata <= aes_ct[31:0];
                    default: s_axi_rdata <= 32'b0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
