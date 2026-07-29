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
// NOTE: also verify this array's size against how soc_top.v masks
// addresses for this module (`cpu_dmem_addr & 32'h0000FFFF`, which
// allows word indices up to 16383). This array is only [0:2047]
// (2048 words = 8KB). If your linker script (link.ld) places data/
// stack anywhere past byte offset 0x1FFC, that access will fall
// outside this array. Check link.ld's memory region size and either
// widen this array to [0:16383] or narrow the mask in soc_top.v to
// 32'h00001FFF to match -- whichever matches your intended RAM size.
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