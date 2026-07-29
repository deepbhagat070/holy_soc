`timescale 1ns / 1ps

module ex_mem_reg (
    input  wire        clk, rst, en, 
    input  wire        clr, // NEW: Added synchronous clear port
    input  wire        ex_RegWrite, 
    input  wire [2:0]  ex_MemtoReg, 
    input  wire        ex_MemRead, ex_MemWrite, 
    input  wire [2:0]  ex_funct3, 
    input  wire [31:0] ex_alu_result, ex_rs2_data, 
    input  wire [4:0]  ex_rd_addr, 
    input  wire [31:0] ex_pc_plus_4, ex_pc, ex_imm_ext, ex_branch_target,
    input  wire        ex_is_ecall, ex_is_mret, ex_is_ebreak, 
    input  wire        ex_csr_we,
    input  wire [11:0] ex_csr_addr,
    input  wire [31:0] ex_csr_wdata, ex_csr_rdata, 

    output reg         mem_RegWrite, 
    output reg  [2:0]  mem_MemtoReg, 
    output reg         mem_MemRead, mem_MemWrite, 
    output reg  [2:0]  mem_funct3, 
    output reg  [31:0] mem_alu_result, mem_rs2_data, 
    output reg  [4:0]  mem_rd_addr, 
    output reg  [31:0] mem_pc_plus_4, mem_pc, mem_imm_ext, mem_branch_target,
    output reg         mem_is_ecall, mem_is_mret, mem_is_ebreak,
    output reg         mem_csr_we,
    output reg  [11:0] mem_csr_addr,
    output reg  [31:0] mem_csr_wdata, mem_csr_rdata
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_RegWrite <= 1'b0; mem_MemtoReg <= 3'b0; mem_MemRead <= 1'b0;
            mem_MemWrite <= 1'b0; mem_funct3 <= 3'b0; mem_alu_result <= 32'b0;
            mem_rs2_data <= 32'b0; mem_rd_addr <= 5'b0; mem_pc_plus_4 <= 32'b0;
            mem_pc <= 32'b0; mem_imm_ext <= 32'b0; mem_branch_target <= 32'b0;
            mem_is_ecall <= 1'b0; mem_is_mret <= 1'b0; mem_is_ebreak <= 1'b0;
            mem_csr_we <= 1'b0; mem_csr_addr <= 12'b0; mem_csr_wdata <= 32'b0;
            mem_csr_rdata <= 32'b0;
        end else if (en) begin
            // NEW: Added synchronous bubble injection for control signals
            if (clr) begin
                mem_RegWrite  <= 1'b0; 
                mem_MemRead   <= 1'b0;
                mem_MemWrite  <= 1'b0; 
                mem_is_ecall  <= 1'b0; 
                mem_is_mret   <= 1'b0; 
                mem_is_ebreak <= 1'b0;
                mem_csr_we    <= 1'b0; 
            end else begin
                // OLD: These were previously unconditional inside the en block
                mem_RegWrite <= ex_RegWrite; mem_MemtoReg <= ex_MemtoReg; mem_MemRead <= ex_MemRead;
                mem_MemWrite <= ex_MemWrite; mem_funct3 <= ex_funct3; mem_alu_result <= ex_alu_result;
                mem_rs2_data <= ex_rs2_data; mem_rd_addr <= ex_rd_addr; mem_pc_plus_4 <= ex_pc_plus_4;
                mem_pc <= ex_pc; mem_imm_ext <= ex_imm_ext; mem_branch_target <= ex_branch_target;
                mem_is_ecall <= ex_is_ecall; mem_is_mret <= ex_is_mret; mem_is_ebreak <= ex_is_ebreak;
                mem_csr_we <= ex_csr_we; mem_csr_addr <= ex_csr_addr; mem_csr_wdata <= ex_csr_wdata;
                mem_csr_rdata <= ex_csr_rdata;
            end
        end
    end
endmodule