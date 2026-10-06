

module aes_axi_lite_slave (
    input  wire        aclk,
    input  wire        aresetn,
    
    
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    
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

    
    
    
    reg [31:0] awaddr_reg;
    reg        aw_en;
    
    reg [31:0] wdata_reg;
    reg        w_en;

    
    assign s_axi_awready = ~aw_en && ~s_axi_bvalid;
    assign s_axi_wready  = ~w_en  && ~s_axi_bvalid;

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
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            key_reg      <= 128'b0;
            pt_reg       <= 128'b0;
            start_pulse  <= 1'b0;
        end else begin
            start_pulse <= 1'b0; 
            
            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                
                
                case (awaddr_reg[7:0])
                    8'h00: key_reg[127:96] <= wdata_reg;
                    8'h04: key_reg[95:64]  <= wdata_reg;
                    8'h08: key_reg[63:32]  <= wdata_reg;
                    8'h0C: key_reg[31:0]   <= wdata_reg;
                    8'h10: pt_reg[127:96]  <= wdata_reg;
                    8'h14: pt_reg[95:64]   <= wdata_reg;
                    8'h18: pt_reg[63:32]   <= wdata_reg;
                    8'h1C: pt_reg[31:0]    <= wdata_reg;
                    8'h20: start_pulse     <= wdata_reg[0];
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    
    
    
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
                case (araddr_reg[7:0])
                    8'h24: s_axi_rdata <= {30'b0, aes_done_latched, 1'b0}; 
                    8'h28: s_axi_rdata <= ciphertext[127:96];
                    8'h2C: s_axi_rdata <= ciphertext[95:64];
                    8'h30: s_axi_rdata <= ciphertext[63:32];
                    8'h34: s_axi_rdata <= ciphertext[31:0];
                    default: s_axi_rdata <= 32'b0; 
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    
    
    
    
    
    
    
    
    
    always @(posedge aclk) begin
        if (~aresetn) begin
            aes_done_latched <= 1'b0;
        end else begin
            if (start_pulse) begin
                aes_done_latched <= 1'b0; 
            end else if (aes_done) begin
                aes_done_latched <= 1'b1; 
            end
        end
    end

endmodule