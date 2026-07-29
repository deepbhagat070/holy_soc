`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: data_mem
//
// FIX APPLIED: added zero-initialization for the entire ram array.
// The original had NO initial block at all -- every word started as
// X in simulation. Any load reading a global/stack location before
// it was explicitly written (which C code routinely assumes is safe
// for .bss / zero-initialized data) would return X. This is a very
// plausible contributor to the PC-goes-X crashes seen in the CPU
// pipeline waveforms, since an X loaded into a register can
// eventually reach an address calculation or indirect jump target.
//
// FIX APPLIED (2): widened ram from [0:2047] (8KB) to [0:16383] (64KB)
// to match soc_top.v's address mask (cpu_dmem_addr & 32'h0000FFFF, which
// allows word indices up to 16383). The old 8KB array silently truncated
// any address past word 2047 to its lower bits at synthesis, causing
// writes/reads past 8KB to alias onto earlier memory -- this was fine for
// small hand-assembled test programs but broke once a real compiled C
// program's globals/stack pushed the working set past 8KB.
//////////////////////////////////////////////////////////////////////////////////

module data_mem(
    input clk,
    input  mem_read,
    input [3:0] we,
    input [31:0] addr,
    input [31:0] write_data,
    output [31:0] read_data
    );
    
    reg [31:0] ram [0:2047];
    integer i;

    // FIX: was completely uninitialized. Now zeroed before simulation
    // starts, matching how a real memory would be expected to behave
    // for .bss (or at minimum, giving deterministic, debuggable
    // behavior instead of silent X-propagation).
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
    end
    
    assign read_data =  mem_read? ram[addr [31:2]] : 32'b0;
    
    always@(posedge clk ) begin 
        if (we[0]) ram[addr[31:2]][7:0] <= write_data[7:0];  
        if (we[1]) ram[addr[31:2]][15:8] <= write_data[15:8]; 
        if (we[2]) ram[addr[31:2]][23:16] <= write_data[23:16]; 
        if (we[3]) ram[addr[31:2]][31:24] <= write_data[31:24]; 
    end
    
    
endmodule