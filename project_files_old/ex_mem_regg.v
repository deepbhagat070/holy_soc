`timescale 1ns / 1ps

module ex_mem_reg(
    input             clk,
    input             rst,
    input             en,
    
    // Control
    input             ex_RegWrite,
    input      [2:0]  ex_MemtoReg,
    input             ex_MemRead,
    input             ex_MemWrite,
    input      [2:0]  ex_funct3,
    
    // Datapath
    input      [31:0] ex_alu_result,
    input      [31:0] ex_rs2_data,
    input      [4:0]  ex_rd_addr,
    
    input      [31:0] ex_pc_plus_4,     // NEW: Passing down bookmark
    input      [31:0] ex_imm_ext,       // NEW: Passing down LUI data
    input      [31:0] ex_branch_target, // NEW: Calculated in EX (PC + imm)
    
    // Outputs to Memory Stage
    output reg        mem_RegWrite,
    output reg [2:0]  mem_MemtoReg,
    output reg        mem_MemRead,
    output reg        mem_MemWrite,
    output reg [2:0]  mem_funct3,
    
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data,
    output reg [4:0]  mem_rd_addr,
    
    output reg [31:0] mem_pc_plus_4,    // NEW
    output reg [31:0] mem_imm_ext,      // NEW
    output reg [31:0] mem_branch_target // NEW
);

    always @(posedge clk) begin
        if (rst) begin
            mem_RegWrite   <= 1'b0;  mem_MemtoReg   <= 3'b0;
            mem_MemRead    <= 1'b0;  mem_MemWrite   <= 1'b0;
            mem_funct3     <= 3'b0;
            
            mem_alu_result <= 32'b0; mem_rs2_data   <= 32'b0;
            mem_rd_addr    <= 5'b0;
            
            mem_pc_plus_4  <= 32'b0; mem_imm_ext    <= 32'b0;
            mem_branch_target <= 32'b0;
        end else if (en) begin
            mem_RegWrite   <= ex_RegWrite;   mem_MemtoReg   <= ex_MemtoReg;
            mem_MemRead    <= ex_MemRead;    mem_MemWrite   <= ex_MemWrite;
            mem_funct3     <= ex_funct3;
            
            mem_alu_result <= ex_alu_result; mem_rs2_data   <= ex_rs2_data;
            mem_rd_addr    <= ex_rd_addr;
            
            mem_pc_plus_4  <= ex_pc_plus_4;  mem_imm_ext    <= ex_imm_ext;
            mem_branch_target <= ex_branch_target;
        end
    end
endmodule