`timescale 1ns / 1ps

module mem_wb_reg (
    input  wire        clk, rst, en, 
    input  wire        clr, 
    input  wire        mem_RegWrite, 
    input  wire [2:0]  mem_MemtoReg, 
    input  wire [31:0] mem_read_data, mem_alu_result, 
    input  wire [4:0]  mem_rd_addr, 
    input  wire [31:0] mem_pc_plus_4, mem_imm_ext, mem_branch_target,
    input  wire        mem_is_ecall, mem_is_mret, mem_is_ebreak, 
    input  wire [31:0] mem_pc,
    input  wire        mem_csr_we,
    input  wire [11:0] mem_csr_addr,
    input  wire [31:0] mem_csr_wdata, mem_csr_rdata,

    output reg         wb_RegWrite, 
    output reg  [2:0]  wb_MemtoReg, 
    output reg  [31:0] wb_read_data, wb_alu_result, 
    output reg  [4:0]  wb_rd_addr, 
    output reg  [31:0] wb_pc_plus_4, wb_imm_ext, wb_branch_target,
    output reg         wb_is_ecall, wb_is_mret, wb_is_ebreak, 
    output reg  [31:0] wb_pc,
    output reg         wb_csr_we,
    output reg  [11:0] wb_csr_addr,
    output reg  [31:0] wb_csr_wdata, wb_csr_rdata
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_RegWrite <= 1'b0; wb_MemtoReg <= 3'b0; wb_read_data <= 32'b0;
            wb_alu_result <= 32'b0; wb_rd_addr <= 5'b0; wb_pc_plus_4 <= 32'b0;
            wb_imm_ext <= 32'b0; wb_branch_target <= 32'b0; wb_is_ecall <= 1'b0;
            wb_is_mret <= 1'b0; wb_is_ebreak <= 1'b0; wb_pc <= 32'b0;
            wb_csr_we <= 1'b0; wb_csr_addr <= 12'b0; wb_csr_wdata <= 32'b0;
            wb_csr_rdata <= 32'b0;
        end else if (en) begin
            if (clr) begin
                wb_RegWrite  <= 1'b0;
                wb_is_ecall  <= 1'b0;
                wb_is_mret   <= 1'b0;
                wb_is_ebreak <= 1'b0;
                wb_csr_we    <= 1'b0;
            end else begin
                wb_RegWrite <= mem_RegWrite; wb_MemtoReg <= mem_MemtoReg; wb_read_data <= mem_read_data;
                wb_alu_result <= mem_alu_result; wb_rd_addr <= mem_rd_addr; wb_pc_plus_4 <= mem_pc_plus_4;
                wb_imm_ext <= mem_imm_ext; wb_branch_target <= mem_branch_target; wb_is_ecall <= mem_is_ecall;
                wb_is_mret <= mem_is_mret; wb_is_ebreak <= mem_is_ebreak; wb_pc <= mem_pc;
                wb_csr_we <= mem_csr_we; wb_csr_addr <= mem_csr_addr; wb_csr_wdata <= mem_csr_wdata;
                wb_csr_rdata <= mem_csr_rdata;
            end
        end
    end
endmodule