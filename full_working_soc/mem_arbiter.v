`timescale 1ns / 1ps

module mem_arbiter (
    input  wire        clk,
    input  wire        rst,

    
    input  wire        i_bus_req,
    input  wire [31:0] i_bus_addr,
    output wire        i_bus_grant,

    
    input  wire        d_bus_req,
    input  wire [31:0] d_bus_addr,
    input  wire [31:0] d_bus_wdata,
    input  wire [3:0]  d_bus_wstrb,
    output wire        d_bus_grant,

    
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

    
    
    
    localparam [1:0]
        IDLE   = 2'd0,
        I_LOCK = 2'd1,
        D_LOCK = 2'd2;

    reg [1:0] state;

    
    
    
    assign i_bus_grant = (state == I_LOCK);
    assign d_bus_grant = (state == D_LOCK);

    
    
    
    assign cache_bus_ready = mem_bus_ready;
    assign cache_bus_rdata = mem_bus_rdata;

    
    
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)

                IDLE: begin
                    
                    if (d_bus_req)
                        state <= D_LOCK;
                    else if (i_bus_req)
                        state <= I_LOCK;
                end

                I_LOCK: begin
                    
                    if (!i_bus_req)
                        state <= IDLE;
                end

                D_LOCK: begin
                    
                    if (!d_bus_req)
                        state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    
    
    
    always @(*) begin
        mem_bus_req   = 1'b0;
        mem_bus_addr  = 32'b0;
        mem_bus_wdata = 32'b0;
        mem_bus_wstrb = 4'b0000;

        case (state)

            IDLE: begin
                
                if (d_bus_req) begin
                    mem_bus_req   = 1'b1;
                    mem_bus_addr  = d_bus_addr;
                    mem_bus_wdata = d_bus_wdata;
                    mem_bus_wstrb = d_bus_wstrb;
                end else if (i_bus_req) begin
                    mem_bus_req  = 1'b1;
                    mem_bus_addr = i_bus_addr;
                end
            end

            I_LOCK: begin
                mem_bus_req  = i_bus_req;
                mem_bus_addr = i_bus_addr;
            end

            D_LOCK: begin
                mem_bus_req   = d_bus_req;
                mem_bus_addr  = d_bus_addr;
                mem_bus_wdata = d_bus_wdata;
                mem_bus_wstrb = d_bus_wstrb;
            end

            default: begin end
        endcase
    end

endmodule