`timescale 1ns / 1ps

module csr_file (
    input  wire        clk,
    input  wire        rst,
    
    input  wire [11:0] csr_raddr,
    input  wire [11:0] csr_waddr,
    input  wire        csr_we,
    input  wire [31:0] csr_wdata,
    input wire         ext_irq,
    output reg  [31:0] csr_rdata,

    input  wire        trap_taken,
    input  wire [31:0] trap_pc,
    input  wire [31:0] trap_cause,
    input  wire [31:0] trap_val,
    input  wire        mret_taken,

    output wire [31:0] mtvec_out,
    output wire [31:0] mepc_out,
    output wire        mie_out
);

    reg [31:0] mtvec;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mstatus;
    reg [31:0] mscratch; 
    reg  [31:0] mie;
    wire [31:0] mip;

    assign mtvec_out = mtvec;
    assign mepc_out  = mepc;
    assign mie_out   = mstatus[3];
    assign mip = {20'b0, ext_irq, 11'b0};
    
    always @(*) begin
        case (csr_raddr)
            12'h300: csr_rdata = mstatus;
            12'h304: csr_rdata = mie;
            12'h305: csr_rdata = mtvec;
            12'h340: csr_rdata = mscratch; 
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h344: csr_rdata = mip;
            default: csr_rdata = 32'b0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mtvec    <= 32'b0;
            mepc     <= 32'b0;
            mcause   <= 32'b0;
            mstatus  <= 32'b0;
            mscratch <= 32'b0; 
            mie      <= 32'b0;
        end else begin
            if (csr_we) begin
                case (csr_waddr)
                    12'h300: mstatus  <= csr_wdata;
                    12'h305: mtvec    <= csr_wdata;
                    12'h304: mie      <= csr_wdata;
                    12'h340: mscratch <= csr_wdata; 
                    12'h341: mepc     <= csr_wdata;
                    12'h342: mcause   <= csr_wdata;
                endcase
            end

            if (trap_taken) begin
                mepc       <= trap_pc;
                mcause     <= trap_cause;
                mstatus[7] <= mstatus[3];
                mstatus[3] <= 1'b0;
            end else if (mret_taken) begin
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;
            end
        end
    end
endmodule