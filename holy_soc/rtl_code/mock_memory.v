`timescale 1ns / 1ps

module mock_memory (
    input  wire        clk,
    input  wire        rst,
    
    input  wire        bus_req,
    input  wire [3:0]  bus_wstrb,
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    
    output reg         bus_grant,
    output reg         bus_ready,
    output reg  [31:0] bus_rdata
);

    reg [31:0] ram [0:8191]; // 32KB RAM
    
    // Initialize RAM with identifiable data
    integer i;
    initial begin
        for (i = 0; i < 8192; i = i + 1) begin
            ram[i] = {16'hAAAA, i[15:0]}; 
        end
    end

    localparam IDLE    = 3'd0;
    localparam DELAY   = 3'd1;
    localparam BURST_R = 3'd2;
    localparam BURST_W = 3'd3;
    localparam SING_R  = 3'd4;
    localparam SING_W  = 3'd5;

    reg [2:0] state;
    reg [2:0] delay_cnt;
    reg [1:0] burst_cnt;
    reg [31:0] base_addr;

    wire is_cacheable = (bus_addr >= 32'h2000_0000);
    
    // Mask address to fit within the 8192-word (13-bit index) bounds
    wire [12:0] ram_idx = base_addr[14:2]; 

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            bus_grant <= 1'b0;
            bus_ready <= 1'b0;
            bus_rdata <= 32'b0;
            delay_cnt <= 3'd0;
            burst_cnt <= 2'b00;
        end else begin
            // Default assignments
            bus_ready <= 1'b0;
            bus_grant <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (bus_req) begin
                        state <= DELAY;
                        delay_cnt <= 3'd3; // 3-cycle artificial latency
                        base_addr <= bus_addr;
                    end
                end

                DELAY: begin
                    if (delay_cnt == 0) begin
                        bus_grant <= 1'b1;
                        if (is_cacheable)
                            state <= (bus_wstrb == 4'b1111) ? BURST_W : BURST_R;
                        else
                            state <= (bus_wstrb != 4'b0000) ? SING_W : SING_R;
                    end else begin
                        delay_cnt <= delay_cnt - 1;
                    end
                end

                BURST_R: begin
                    bus_ready <= 1'b1;
                    bus_rdata <= ram[ram_idx + burst_cnt];
                    if (burst_cnt == 2'b11) begin
                        state <= IDLE;
                        burst_cnt <= 2'b00;
                    end else begin
                        burst_cnt <= burst_cnt + 1;
                    end
                end

                BURST_W: begin
                    bus_ready <= 1'b1;
                    ram[ram_idx + burst_cnt] <= bus_wdata;
                    if (burst_cnt == 2'b11) begin
                        state <= IDLE;
                        burst_cnt <= 2'b00;
                    end else begin
                        burst_cnt <= burst_cnt + 1;
                    end
                end

                SING_R: begin
                    bus_ready <= 1'b1;
                    bus_rdata <= ram[ram_idx];
                    state <= IDLE;
                end

                SING_W: begin
                    bus_ready <= 1'b1;
                    if (bus_wstrb[0]) ram[ram_idx][7:0]   <= bus_wdata[7:0];
                    if (bus_wstrb[1]) ram[ram_idx][15:8]  <= bus_wdata[15:8];
                    if (bus_wstrb[2]) ram[ram_idx][23:16] <= bus_wdata[23:16];
                    if (bus_wstrb[3]) ram[ram_idx][31:24] <= bus_wdata[31:24];
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule