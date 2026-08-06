`timescale 1ns / 1ps

module alu_control(
    input      [1:0] ALUOp,
    input      [2:0] funct3,
    input            bit30,
    input            ALUSrc,
    output reg [3:0] ALU_Ctrl
);

    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam AND  = 4'b0010;
    localparam OR   = 4'b0011;
    localparam XOR  = 4'b0100;
    localparam SLL  = 4'b0101;
    localparam SRL  = 4'b0110;
    localparam SRA  = 4'b0111;
    localparam SLT  = 4'b1000;
    localparam SLTU = 4'b1001;

    always @(*) begin
        case(ALUOp)
            2'b00: ALU_Ctrl = ADD; 

            2'b01: begin
                case(funct3)
                    3'b000: ALU_Ctrl = SUB;
                    3'b001: ALU_Ctrl = SUB;
                    3'b100: ALU_Ctrl = SLT;
                    3'b101: ALU_Ctrl = SLT;
                    3'b110: ALU_Ctrl = SLTU;
                    3'b111: ALU_Ctrl = SLTU;
                    default: ALU_Ctrl = SUB;
                endcase
            end

            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if (bit30 == 1'b1 && ALUSrc == 1'b0) ALU_Ctrl = SUB;
                        else                                 ALU_Ctrl = ADD;
                    end
                    
                    3'b001: ALU_Ctrl = SLL;
                    3'b010: ALU_Ctrl = SLT;
                    3'b011: ALU_Ctrl = SLTU;
                    3'b100: ALU_Ctrl = XOR;
                    
                    3'b101: begin
                        if (bit30 == 1'b1) ALU_Ctrl = SRA;
                        else               ALU_Ctrl = SRL;
                    end
                    
                    3'b110: ALU_Ctrl = OR;
                    3'b111: ALU_Ctrl = AND;
                    
                    default: ALU_Ctrl = ADD;
                endcase
            end

            default: ALU_Ctrl = ADD; 
        endcase
    end

endmodule