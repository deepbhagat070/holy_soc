`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 09:32:18
// Design Name: 
// Module Name: inst_mem
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
`timescale 1ns / 1ps

module inst_mem (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:8191]; // 32KB Instruction Memory

    initial begin
        $readmemh("C:/Users/Admin/Desktop/Internship_prep/firmware/program.txt", mem);
    end

    // Mask to 13 bits (8192 words) to prevent out-of-bounds reads
    wire [12:0] word_addr = pc[14:2];
    assign instruction = mem[word_addr];

endmodule
