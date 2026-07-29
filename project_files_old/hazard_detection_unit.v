`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 11:41:54
// Design Name: 
// Module Name: hazard_detection_unit
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

module hazard_detection_unit(
    input [4:0] id_rs1_addr,
    input [4:0] id_rs2_addr,
    
    input [4:0] ex_rd_addr,
    input ex_MemRead,
    
    output reg pc_write, 
    output reg if_id_write,
    output reg stall_mux
    );
    
    always@(*) begin 
        if( ex_MemRead  && ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr))) begin
            pc_write = 1'b0;
            if_id_write = 1'b0;
            stall_mux = 1'b1;            
        end
        else begin
            pc_write =1'b1;
            if_id_write =1'b1;
            stall_mux = 1'b0;
        end
        
    end
    
endmodule
