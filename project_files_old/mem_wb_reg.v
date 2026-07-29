`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 18:48:26
// Design Name: 
// Module Name: mem_wb_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module mem_wb_reg(
    input             clk,
    input             rst,
    
    // Control
    input             mem_RegWrite,
    input      [2:0]  mem_MemtoReg,
    
    // Datapath
    input      [31:0] mem_read_data,
    input      [31:0] mem_alu_result,
    input      [4:0]  mem_rd_addr,
    
    input      [31:0] mem_pc_plus_4,     // NEW
    input      [31:0] mem_imm_ext,       // NEW
    input      [31:0] mem_branch_target, // NEW
    input             en,
    
    // Outputs to Writeback Stage
    output reg        wb_RegWrite,
    output reg [2:0]  wb_MemtoReg,
    
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_rd_addr,
    
    output reg [31:0] wb_pc_plus_4,      // NEW
    output reg [31:0] wb_imm_ext,        // NEW
    output reg [31:0] wb_branch_target   // NEW
);

    always @(posedge clk) begin
        if (rst) begin
            wb_RegWrite   <= 1'b0;  wb_MemtoReg   <= 3'b0;
            
            wb_read_data  <= 32'b0; wb_alu_result <= 32'b0;
            wb_rd_addr    <= 5'b0;
            
            wb_pc_plus_4  <= 32'b0; wb_imm_ext    <= 32'b0;
            wb_branch_target <= 32'b0;
        end else if (en) begin
            wb_RegWrite   <= mem_RegWrite;   wb_MemtoReg   <= mem_MemtoReg;
            
            wb_read_data  <= mem_read_data;  wb_alu_result <= mem_alu_result;
            wb_rd_addr    <= mem_rd_addr;
            
            wb_pc_plus_4  <= mem_pc_plus_4;  wb_imm_ext    <= mem_imm_ext;
            wb_branch_target <= mem_branch_target;
        end
    end
endmodule