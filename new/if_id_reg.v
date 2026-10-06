`timescale 1ns / 1ps

module if_id_reg(
    input             clk,
    input             rst,
    input             clr,
    input             en,
    
    input      [31:0] if_pc,
    input      [31:0] if_pc_plus_4,   
    input      [31:0] if_instruction,
   
    output reg [31:0] id_pc,
    output reg [31:0] id_pc_plus_4, 
    output reg [31:0] id_instruction
);

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            id_pc          <= 32'b0;
            id_pc_plus_4   <= 32'b0;
            id_instruction <= 32'b0;
        end else if (en) begin
            if (clr) begin
                id_instruction <= 32'h00000013; 
                id_pc          <= 32'b0; 
                id_pc_plus_4   <= 32'b0;
            end else begin 
                id_pc          <= if_pc;
                id_pc_plus_4   <= if_pc_plus_4;
                id_instruction <= if_instruction;
            end
        end
    end
endmodule
//