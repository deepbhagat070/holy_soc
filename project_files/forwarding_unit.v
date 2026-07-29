`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 15:47:40
// Design Name: 
// Module Name: forwarding_unit
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

module forwarding_unit(
    // Inputs from Stage 2/3 Wall (What the ALU currently wants to use)
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    
    // Inputs from Stage 3/4 Wall (The older instruction right ahead of us)
    input [4:0] ex_mem_rd,
    input ex_mem_regwrite,
    
    // Inputs from Stage 4/5 Wall (The oldest instruction two steps ahead)
    input [4:0] mem_wb_rd,
    input mem_wb_regwrite,
    
    // Outputs to drive your new 3-to-1 multiplexers
    output reg [1:0] forward_A,
    output reg [1:0] forward_B
);

    // Forwarding logic for ALU Input A (rs1)
    always @(*) begin
        // Priority 1: EX Hazard (Data is right ahead of us in Wall 3)
        if (ex_mem_regwrite && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs1)) begin
            forward_A = 2'b10; 
        end
        // Priority 2: MEM Hazard (Data is two steps ahead in Wall 4)
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs1)) begin
            forward_A = 2'b01; 
        end
        // Default: No Hazard
        else begin
            forward_A = 2'b00; 
        end
    end

    // Forwarding logic for ALU Input B (rs2)
    always @(*) begin
        if (ex_mem_regwrite && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs2)) begin
            forward_B = 2'b10; 
        end
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs2)) begin
            forward_B = 2'b01; 
        end
        else begin
            forward_B = 2'b00; 
        end
    end

endmodule
