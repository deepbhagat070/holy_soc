`timescale 1ns / 1ps

module csr_alu (
    input  wire [31:0] csr_rdata,
    input  wire [31:0] op_data,    // Driven by the ALUSrc mux (rs1_data or Z-type imm)
    input  wire [2:0]  funct3,     // Pipelined from decode stage
    output reg  [31:0] csr_wdata
);

    always @(*) begin
        case (funct3[1:0])
            2'b01: csr_wdata = op_data;                 // csrrw  / csrrwi
            2'b10: csr_wdata = csr_rdata | op_data;     // csrrs  / csrrsi
            2'b11: csr_wdata = csr_rdata & ~op_data;    // csrrc  / csrrci
            default: csr_wdata = 32'b0;                 // Prevent latches
        endcase
    end

endmodule
