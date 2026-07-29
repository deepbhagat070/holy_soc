`timescale 1ns / 1ps

module main_control(
    input      [6:0] opcode,
    
    output reg       Branch,
    output reg       MemRead,
    output reg [1:0] ALUOp,
    output reg       MemWrite,
    output reg       ALUSrc,
    output reg       RegWrite,
    output reg [2:0] ImmSrc,
    output reg [1:0] Jump,     
    output reg [2:0] MemtoReg,
    output reg [1:0] ALUSrcA    // NEW: ALU Input A multiplexer control
);

    localparam R_TYPE = 7'b0110011;
    localparam I_LOAD = 7'b0000011;
    localparam S_TYPE = 7'b0100011;
    localparam B_TYPE = 7'b1100011;
    localparam I_MATH = 7'b0010011;
    localparam J_TYPE = 7'b1101111; 
    localparam JALR   = 7'b1100111; 
    localparam LUI    = 7'b0110111; 
    localparam AUIPC  = 7'b0010111; 

    always @(*) begin
        
        Branch   = 1'b0; 
        MemRead  = 1'b0;
        MemtoReg = 3'b000; 
        MemWrite = 1'b0; 
        ALUSrc   = 1'b0; 
        ALUSrcA  = 2'b00;       // Default: Route rs1 to ALU Input A
        RegWrite = 1'b0; 
        ALUOp    = 2'b00;
        ImmSrc   = 3'b000;
        Jump     = 2'b00;

        case(opcode)
            R_TYPE: begin RegWrite=1; ALUSrc=0; MemtoReg=3'b000; ALUOp=2'b10; end
            I_MATH: begin RegWrite=1; ALUSrc=1; MemtoReg=3'b000; ImmSrc=3'b000; ALUOp=2'b10; end
            I_LOAD: begin RegWrite=1; ALUSrc=1; MemtoReg=3'b001; MemRead=1; ImmSrc=3'b000; ALUOp=2'b00; end
            S_TYPE: begin ALUSrc=1; MemWrite=1; ImmSrc=3'b001; ALUOp=2'b00; end
            B_TYPE: begin Branch=1; ALUSrc=0; ImmSrc=3'b010; ALUOp=2'b01; end
            J_TYPE: begin Jump=2'b01; RegWrite=1; MemtoReg=3'b010; ImmSrc=3'b100; end
            JALR:   begin Jump=2'b10; RegWrite=1; MemtoReg=3'b010; ImmSrc=3'b000; ALUOp=2'b00; ALUSrc=1; end
            
            // U-Type instructions bypass rs1 completely
            LUI:    begin RegWrite=1'b1; ALUSrc=1'b1; ALUSrcA=2'b10; ALUOp=2'b00; ImmSrc=3'b011; MemtoReg=3'b000; end
            AUIPC:  begin RegWrite=1'b1; ALUSrc=1'b1; ALUSrcA=2'b01; ALUOp=2'b00; ImmSrc=3'b011; MemtoReg=3'b000; end
        endcase
    end
endmodule