`timescale 1ns / 1ps




module tb_soc_top;

    
    reg  clk;
    reg  rst;
    wire uart_tx;
    wire ext_irq;
    wire uart_rx;
    
    soc_top uut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .ext_irq(ext_irq)
    );

    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        rst = 1;
        #20; 
        rst = 0;
        #450000000;
        
        $display("Simulation complete. Check the uart_tx waveform!");
        $finish;
    end

endmodule
