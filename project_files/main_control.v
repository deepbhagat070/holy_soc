`timescale 1ns / 1ps

module main_control (
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [11:0] imm12,
    input  wire [4:0]  rs1_addr,
    output reg         Branch,
    output reg         MemRead,
    output reg  [1:0]  ALUOp,
    output reg         MemWrite,
    output reg         ALUSrc,
    output reg  [1:0]  ALUSrcA,
    output reg         RegWrite,
    output reg  [2:0]  ImmSrc,
    output reg  [1:0]  Jump,
    output reg  [2:0]  MemtoReg,
    output reg         id_csr_we,
    output reg         Is_System,
    output reg         is_ecall,
    output reg         is_ebreak,
    output reg         is_mret
);

    always @(*) begin
        Branch    = 1'b0;
        MemRead   = 1'b0;
        ALUOp     = 2'b00;
        MemWrite  = 1'b0;
        ALUSrc    = 1'b0;
        ALUSrcA   = 2'b00;
        RegWrite  = 1'b0;
        ImmSrc    = 3'b000;
        Jump      = 2'b00;
        MemtoReg  = 3'b000;
        id_csr_we = 1'b0;
        Is_System = 1'b0;
        is_ecall  = 1'b0;
        is_ebreak = 1'b0;
        is_mret = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b10;
            end
            7'b0000011: begin // Load
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 3'b001;
            end
            7'b0100011: begin // Store
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ImmSrc   = 3'b001;
            end
            7'b1100011: begin // Branch
                Branch   = 1'b1;
                ALUSrcA  = 2'b01; 
                ImmSrc   = 3'b010;
            end
            
            7'b1100111: begin // JALR
                RegWrite = 1'b1;
                Jump     = 2'b10;
                ALUSrc   = 1'b1;
                MemtoReg = 3'b010; 
            end
            7'b1101111: begin // JAL
                RegWrite = 1'b1;
                Jump     = 2'b01;
                ALUSrcA  = 2'b01; 
                MemtoReg = 3'b010; 
                ImmSrc   = 3'b100;
            end
            7'b0110111: begin // LUI
                RegWrite = 1'b1;
                ALUSrcA  = 2'b10; 
                ALUSrc   = 1'b1;
                MemtoReg = 3'b011; 
                ImmSrc   = 3'b011;
            end
            7'b0010111: begin // AUIPC
                RegWrite = 1'b1;
                ALUSrcA  = 2'b01; 
                ALUSrc   = 1'b1;
                MemtoReg = 3'b000; 
                ImmSrc   = 3'b011;
            end
                
            7'b1110011: begin // SYSTEM
                Is_System = 1'b1;
                if (funct3 == 3'b000) begin
                    if (imm12 == 12'h000) is_ecall = 1'b1;
                    else if (imm12 == 12'h001) is_ebreak = 1'b1; // changes if to else if 
                    else if (imm12 == 12'h302) is_mret = 1'b1;
                end else begin
                    RegWrite = 1'b1;
                    MemtoReg = 3'b101; 
                    if (funct3[2] == 1'b1) begin
                        ImmSrc = 3'b101; // Define 101 in your ImmGen as Z-type (zero extend rs1)
                        ALUSrc = 1'b1;   // Route this immediate into the execution stage
                    end 
                    if (funct3 == 3'b001 || funct3 == 3'b101) begin
                        id_csr_we = 1'b1;
                    end else if (funct3 == 3'b010 || funct3 == 3'b011 || funct3 == 3'b110 || funct3 == 3'b111) begin
                        id_csr_we = (rs1_addr != 5'b00000);
                    end else begin
                        id_csr_we = 1'b0;
                    end
                end
            end
        endcase
    end
endmodule