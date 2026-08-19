`timescale 1ns / 1ps

module alu(
    input      [31:0] A,
    input      [31:0] B,
    input      [3:0]  alu_ctrl,
    output reg [31:0] alu_result,
    output            zero
);

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0;

    parameter ADD=4'b0000, SUB=4'b0001, AND=4'b0010, 
              OR=4'b0011,  XOR=4'b0100, SLL=4'b0101, 
              SRL=4'b0110, SRA=4'b0111, SLT=4'b1000, SLTU=4'b1001;

    always @(*) begin
        case(alu_ctrl) 
            ADD:  alu_result = A + B;
            SUB:  alu_result = A - B;
            AND:  alu_result = A & B;
            OR:   alu_result = A | B;
            XOR:  alu_result = A ^ B;
            SLL:  alu_result = A << B[4:0];
            SRL:  alu_result = A >> B[4:0];
            SRA:  alu_result = $signed(A) >>> B[4:0];
            SLT:  alu_result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
            SLTU: alu_result = (A < B) ? 32'b1 : 32'b0;
            default: alu_result = 32'b0;
        endcase
    end

endmodule