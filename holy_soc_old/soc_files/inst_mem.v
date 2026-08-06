`timescale 1ns / 1ps


module inst_mem (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

 
    reg [31:0] mem [0:8191]; 
    integer i;

    initial begin
        for (i = 0; i < 8192; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        $readmemh("C:/Users/Admin/Desktop/Internship_prep/firmware/program.txt", mem);
    end

    wire [31:0] word_addr = pc[31:2];
    assign instruction = mem[word_addr];

endmodule