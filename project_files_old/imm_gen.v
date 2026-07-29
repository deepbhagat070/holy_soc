`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.06.2026 13:32:48
// Design Name: 
// Module Name: imm_gen
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


module imm_gen(
    input [31:0] instruction,
    input [2:0] ImmSrc,
    
    output reg [31:0] imm_ext
    );
    parameter I_type=3'b000, S_type=3'b001, B_type=3'b010,
               U_type=3'b011, J_type=3'b100;
    always@(*) begin 
        case(ImmSrc) 
            I_type : imm_ext = {{20{instruction[31]}}, instruction[31:20]};
            S_type : imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            U_type : imm_ext = { instruction[31:12], 12'b0 };
            B_type : imm_ext = { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0 };
            J_type : imm_ext = { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0 };
            default : imm_ext = 32'b0;
            endcase
        end
endmodule
