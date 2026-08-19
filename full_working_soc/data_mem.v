`timescale 1ns / 1ps

module data_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire [3:0]  we,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    
    reg [31:0] ram [0:2047]; 

    // Mask to 11 bits (2048 words) to prevent out-of-bounds X-propagation
    wire [10:0] word_addr = addr[12:2];
    
    assign read_data = mem_read ? ram[word_addr] : 32'b0;
    
    always @(posedge clk) begin 
        if (we[0]) ram[word_addr][7:0]   <= write_data[7:0];  
        if (we[1]) ram[word_addr][15:8]  <= write_data[15:8]; 
        if (we[2]) ram[word_addr][23:16] <= write_data[23:16]; 
        if (we[3]) ram[word_addr][31:24] <= write_data[31:24]; 
    end

endmodule