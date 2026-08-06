`timescale 1ns / 1ps

module mem_arbiter (
    input  wire        clk,
    input  wire        rst,

    input  wire        i_bus_req,
    input  wire [31:0] i_bus_addr,
    output reg         i_bus_grant,

    input  wire        d_bus_req,
    input  wire [31:0] d_bus_addr,
    input  wire [31:0] d_bus_wdata,
    input  wire [3:0]  d_bus_wstrb,
    output reg         d_bus_grant,

    output wire        cache_bus_ready,
    output wire [31:0] cache_bus_rdata,

    output reg         mem_bus_req,
    output reg  [31:0] mem_bus_addr,
    output reg  [31:0] mem_bus_wdata,
    output reg  [3:0]  mem_bus_wstrb,
    input  wire        mem_bus_grant,
    input  wire        mem_bus_ready,
    input  wire [31:0] mem_bus_rdata
);

    localparam IDLE   = 2'd0;
    localparam I_LOCK = 2'd1;
    localparam D_LOCK = 2'd2;

    reg [1:0] state, next_state;
    reg [2:0] beat_cnt;

    always @(posedge clk) begin
        if (rst || state == IDLE) beat_cnt <= 3'd0;
        else if (mem_bus_ready)   beat_cnt <= beat_cnt + 3'd1;
    end

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    assign cache_bus_ready = mem_bus_ready;
    assign cache_bus_rdata = mem_bus_rdata;

    always @(*) begin
        next_state    = state;
        i_bus_grant   = 1'b0;
        d_bus_grant   = 1'b0;
        mem_bus_req   = 1'b0;
        mem_bus_addr  = 32'b0;
        mem_bus_wdata = 32'b0;
        mem_bus_wstrb = 4'b0000;

        case (state)
            IDLE: begin
                if (d_bus_req) begin 
                    next_state    = D_LOCK;
                    mem_bus_req   = 1'b1;
                    mem_bus_addr  = d_bus_addr;
                    mem_bus_wdata = d_bus_wdata;
                    mem_bus_wstrb = d_bus_wstrb;
                    d_bus_grant   = mem_bus_grant;
                end else if (i_bus_req) begin
                    next_state   = I_LOCK;
                    mem_bus_req  = 1'b1;
                    mem_bus_addr = i_bus_addr;
                    i_bus_grant  = mem_bus_grant;
                end
            end

            I_LOCK: begin
                mem_bus_addr = i_bus_addr;
                if (mem_bus_ready) begin
                    if ((~i_bus_addr[31] && beat_cnt == 3) || (i_bus_addr[31] && beat_cnt == 0))
                        next_state = IDLE;
                end
            end

            D_LOCK: begin
                mem_bus_addr  = d_bus_addr;
                mem_bus_wdata = d_bus_wdata;
                mem_bus_wstrb = d_bus_wstrb;
                if (mem_bus_ready) begin
                    if ((~d_bus_addr[31] && beat_cnt == 3) || (d_bus_addr[31] && beat_cnt == 0))
                        next_state = IDLE;
                end
            end
        endcase
    end
endmodule