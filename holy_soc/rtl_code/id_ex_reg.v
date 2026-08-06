`timescale 1ns / 1ps

module id_ex_reg (
    input  wire        clk, 
    input  wire        rst,
    input  wire        en,
    input  wire        clr, 
    
    input  wire        id_RegWrite, 
    input  wire [2:0]  id_MemtoReg, 
    input  wire        id_MemRead,
    input  wire        id_MemWrite, 
    input  wire        id_ALUSrc, 
    input  wire [1:0]  id_ALUSrcA,
    input  wire [3:0]  id_ALU_Ctrl,
    input  wire [2:0]  id_funct3, 
    input  wire [31:0] id_pc, 
    input  wire [31:0] id_pc_plus_4,
    input  wire [31:0] id_rs1_data, 
    input  wire [31:0] id_rs2_data, 
    input  wire [31:0] id_imm_ext,
    input  wire [4:0]  id_rd_addr,
    input  wire [4:0]  id_rs1_addr, 
    input  wire [4:0]  id_rs2_addr,
    input  wire        id_is_mret,
    input  wire        id_is_ecall,
    input  wire        id_is_ebreak, 
    input  wire        id_csr_we,
    input  wire [11:0] id_csr_addr,
    input  wire [31:0] id_csr_rdata,

    output reg         ex_RegWrite, 
    output reg  [2:0]  ex_MemtoReg, 
    output reg         ex_MemRead,
    output reg         ex_MemWrite, 
    output reg         ex_ALUSrc, 
    output reg  [1:0]  ex_ALUSrcA,
    output reg  [2:0]  ex_funct3,
    output reg  [3:0]  ex_ALU_Ctrl, 
    output reg  [31:0] ex_pc, 
    output reg  [31:0] ex_pc_plus_4,
    output reg  [31:0] ex_rs1_data, 
    output reg  [31:0] ex_rs2_data, 
    output reg  [31:0] ex_imm_ext,
    output reg  [4:0]  ex_rd_addr,
    output reg  [4:0]  ex_rs1_addr,
    output reg  [4:0]  ex_rs2_addr,
    output reg         ex_is_mret,
    output reg         ex_is_ecall,
    output reg         ex_is_ebreak, 
    output reg         ex_csr_we,
    output reg  [11:0] ex_csr_addr,
    output reg  [31:0] ex_csr_rdata
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_RegWrite  <= 1'b0; ex_MemtoReg <= 3'b0; ex_MemRead <= 1'b0;
            ex_MemWrite  <= 1'b0; ex_ALUSrc <= 1'b0; ex_ALUSrcA <= 2'b0;
            ex_funct3    <= 3'b0; ex_ALU_Ctrl <= 4'b0; ex_pc <= 32'b0;
            ex_pc_plus_4 <= 32'b0; ex_rs1_data <= 32'b0; ex_rs2_data <= 32'b0;
            ex_imm_ext   <= 32'b0; ex_rd_addr <= 5'b0; ex_rs1_addr <= 5'b0;
            ex_rs2_addr  <= 5'b0; ex_is_mret <= 1'b0; ex_is_ecall <= 1'b0;
            ex_is_ebreak <= 1'b0; ex_csr_we <= 1'b0; ex_csr_addr <= 12'b0;
            ex_csr_rdata <= 32'b0;
        end else if (en) begin
            if (clr) begin
                ex_RegWrite  <= 1'b0;
                ex_MemWrite  <= 1'b0;
                ex_MemRead   <= 1'b0;
                ex_csr_we    <= 1'b0;
                ex_is_ecall  <= 1'b0;
                ex_is_ebreak <= 1'b0;
                ex_is_mret   <= 1'b0;
            end else begin
                ex_RegWrite  <= id_RegWrite; ex_MemtoReg <= id_MemtoReg; ex_MemRead <= id_MemRead;
                ex_MemWrite  <= id_MemWrite; ex_ALUSrc <= id_ALUSrc; ex_ALUSrcA <= id_ALUSrcA;
                ex_funct3    <= id_funct3; ex_ALU_Ctrl <= id_ALU_Ctrl; ex_pc <= id_pc;
                ex_pc_plus_4 <= id_pc_plus_4; ex_rs1_data <= id_rs1_data; ex_rs2_data <= id_rs2_data;
                ex_imm_ext   <= id_imm_ext; ex_rd_addr <= id_rd_addr; ex_rs1_addr <= id_rs1_addr;
                ex_rs2_addr  <= id_rs2_addr; ex_is_mret <= id_is_mret; ex_is_ecall <= id_is_ecall;
                ex_is_ebreak <= id_is_ebreak; ex_csr_we <= id_csr_we; ex_csr_addr <= id_csr_addr;
                ex_csr_rdata <= id_csr_rdata;
            end
        end
    end
endmodule