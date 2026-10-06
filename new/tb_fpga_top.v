`timescale 1ns / 1ps

module tb_fpga_top();

    reg clk;
    reg rst_n;
    wire uart_tx;
    reg  uart_rx;

    fpga_top dut (
        .clk_in(clk),
        .rst_n(rst_n),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    localparam BAUD_RATE = 115200;
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE; // in ns

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    task send_uart_byte(input [7:0] data);
        integer j;
        begin
            uart_rx = 0; // Start bit
            #(BIT_PERIOD);
            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = data[j];
                #(BIT_PERIOD);
            end
            uart_rx = 1; // Stop bit
            #(BIT_PERIOD);
        end
    endtask

    integer fd;
    integer c;
    reg [7:0] payload_mem [0:4095];
    integer bytes_read;
    integer i;

    initial begin
        rst_n = 0;
        uart_rx = 1;
        #10000;
        rst_n = 1;
        
        // Wait 2ms for bootloader to print "Booting...\n" and start polling
        #2000000; 

        // Send payload.bin
        $display("TESTBENCH: Starting to send payload.bin...");
        fd = $fopen("C:/Users/Admin/Desktop/project_files_ade/full_working_soc/payload/payload.bin", "rb");
        if (fd != 0) begin
            bytes_read = $fread(payload_mem, fd);
            $display("TESTBENCH: Read %0d bytes from payload.bin", bytes_read);
            for (i = 0; i < bytes_read; i = i + 1) begin
                send_uart_byte(payload_mem[i]);
            end
            $fclose(fd);
            // Send termination word 0xFFFFFFFF (8 times to handle unaligned file size)
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
            send_uart_byte(8'hFF);
        end else begin
            $display("Could not open payload.bin");
        end
        
        // Wait 30ms for payload to execute and print the math result
        #30000000; 
        $finish;
    end

    reg [7:0] rx_byte;
    integer i;

    initial begin
        forever begin
            @(negedge uart_tx); // Wait for start bit
            #(BIT_PERIOD / 2); // Middle of start bit
            if (uart_tx == 0) begin
                #(BIT_PERIOD);
                for (i = 0; i < 8; i = i + 1) begin
                    rx_byte[i] = uart_tx;
                    #(BIT_PERIOD);
                end
                // Stop bit
                $write("%c", rx_byte);
            end
        end
    end

endmodule
