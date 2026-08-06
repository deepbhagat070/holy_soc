`timescale 1ns / 1ps


module tb_aes_core();
    reg clk;
    reg reset;
    reg start;
    reg [127:0] plaintext;
    reg [127:0] round_key;

    wire [127:0] ciphertext;
    wire done;

    aes_core uut (
        .clk(clk), 
        .reset(reset), 
        .start(start), 
        .plaintext(plaintext), 
        .round_key(round_key), 
        .ciphertext(ciphertext), 
        .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        start = 0;
        plaintext = 128'h3243f6a8885a308d313198a2e0370734; 
        round_key = 128'h2b7e151628aed2a6abf7158809cf4f3c; 

        #20 reset = 0;
        
        #10 start = 1;
        #10 start = 0;

        wait (done == 1'b1);
        
        $display("AES Encryption Complete!");
        $display("Ciphertext: %h", ciphertext);
        
        #50 $finish;
    end
endmodule
