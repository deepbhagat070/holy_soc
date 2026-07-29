`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 15:45:26
// Design Name: 
// Module Name: urat_txt
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

`timescale 1ns / 1ps

module urat_txt(
    input clk,
    input rst,
    input tx_tick,
    input tx_start,
    input [7:0] data_in,
    
    output reg tx,
    output reg tx_done
);
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] tx_data;
    
    localparam IDLE  = 2'b00;
    localparam FETCH = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    always@(posedge clk) begin 
        if(rst) begin 
            state   <= IDLE;
            tx      <= 1'b1;
            tx_done <= 1'b0;
            bit_idx <= 3'b0;
        end
        else begin 
            tx_done <= 1'b0; // Default to 0, only pulses high for 1 cycle at the end
            
            case (state) 
                IDLE : begin
                    tx <= 1'b1;
                    if (tx_start == 1'b1) begin
                        tx_data <= data_in;
                        state   <= FETCH;
                    end
                end  
                
                FETCH : begin
                // tx_data <= data_in;  <--- DELETE THIS LINE! 
                
                if (tx_tick == 1'b1) begin
                    tx      <= 1'b0; // Drop START bit exactly on the tick
                    bit_idx <= 3'b0; 
                    state   <= DATA; // Go straight to DATA!
                    end
                end  
                
                DATA: begin
                    if (tx_tick) begin
                        tx <= tx_data[bit_idx]; // Put data bit on wire
                        
                        if (bit_idx == 3'd7) begin 
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end
                
                STOP  : begin 
                    if (tx_tick) begin
                        tx      <= 1'b1; // Pull HIGH for the Stop bit!
                        tx_done <= 1'b1; // Tell the system we finished
                        state   <= IDLE;
                    end
                end
            endcase        
        end 
    end    
endmodule
