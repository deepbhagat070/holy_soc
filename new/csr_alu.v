`timescale 1ns / 1ps

module csr_alu (
    input  wire [31:0] csr_rdata,
    input  wire [31:0] op_data,   
    input  wire [2:0]  funct3,     
    output reg  [31:0] csr_wdata
);

    always @(*) begin
        case (funct3[1:0])
            2'b01: csr_wdata = op_data;                 
            2'b10: csr_wdata = csr_rdata | op_data;     
            2'b11: csr_wdata = csr_rdata & ~op_data;   
            default: csr_wdata = 32'b0;                 
        endcase
    end

endmodule
