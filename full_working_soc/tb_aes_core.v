`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.07.2026 10:56:49
// Design Name: 
// Module Name: tb_aes_core
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

module tb_aes_core();
    // Inputs
    reg clk;
    reg reset;
    reg start;
    reg [127:0] plaintext;
    reg [127:0] round_key;

    // Outputs
    wire [127:0] ciphertext;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    aes_core uut (
        .clk(clk), 
        .reset(reset), 
        .start(start), 
        .plaintext(plaintext), 
        .round_key(round_key), 
        .ciphertext(ciphertext), 
        .done(done)
    );

    // 100MHz Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        reset = 1;
        start = 0;
        plaintext = 128'h3243f6a8885a308d313198a2e0370734; // Standard test vector
        round_key = 128'h2b7e151628aed2a6abf7158809cf4f3c; 

        // Release reset
        #20 reset = 0;
        
        // Pulse the start signal
        #10 start = 1;
        #10 start = 0;

        // Wait for the FSM to finish
        wait (done == 1'b1);
        
        $display("AES Encryption Complete!");
        $display("Ciphertext: %h", ciphertext);
        
        #50 $finish;
    end
endmodule
