`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: inst_mem
//
// FIX APPLIED: the zero-init loop previously only covered words
// 0..255 (the first 1KB). Words 256..2047 were left completely
// uninitialized (X) unless $readmemh happened to write every single
// one of them. Any program whose code (or $readmemh output, which
// can include padding/alignment gaps) extends past 1KB would run
// straight into X-valued "instructions" the moment PC crossed that
// boundary -- a likely contributor to the PC-goes-X crashes seen
// with larger test programs. Now the full 2048-word array is zeroed
// before $readmemh loads the actual program on top of it.
//////////////////////////////////////////////////////////////////////////////////

module inst_mem (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

    // FIX (this round): enlarged from [0:2047] (8KB) to [0:8191] (32KB).
    // The torture-test firmware is far larger than any previous test in
    // this project -- its compiled program.txt very likely contained
    // @address entries beyond word 2047, causing $readmemh to hit
    // "Out of bounds address... Read terminated" and silently truncate
    // the rest of the program, which is why some tests never actually
    // ran as written. Give real headroom here.
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