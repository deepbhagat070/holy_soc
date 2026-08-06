`timescale 1ns / 1ps


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