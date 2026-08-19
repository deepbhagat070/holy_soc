`timescale 1ns / 1ps

module tb_dcache();

    reg clk;
    reg rst;

    // CPU Interface
    reg         cpu_req;
    reg  [31:0] cpu_addr;
    reg         cpu_we;
    reg  [31:0] cpu_wdata;
    reg  [3:0]  cpu_wstrb;
    wire [31:0] cpu_rdata;
    wire        cpu_ready;

    // Bus Interface
    wire        bus_req;
    wire [31:0] bus_addr;
    wire        bus_we;
    wire [31:0] bus_wdata;
    wire [3:0]  bus_wstrb;
    wire [31:0] bus_rdata;
    wire        bus_ready;

    dcache u_dcache (
        .clk        (clk),
        .rst        (rst),
        .cpu_req    (cpu_req),
        .cpu_addr   (cpu_addr),
        .cpu_we     (cpu_we),
        .cpu_wdata  (cpu_wdata),
        .cpu_wstrb  (cpu_wstrb),
        .cpu_rdata  (cpu_rdata),
        .cpu_ready  (cpu_ready),
        .bus_req    (bus_req),
        .bus_addr   (bus_addr),
        .bus_we     (bus_we),
        .bus_wdata  (bus_wdata),
        .bus_wstrb  (bus_wstrb),
        .bus_rdata  (bus_rdata),
        .bus_ready  (bus_ready)
    );

    fake_memory #(
        .LATENCY(3)
    ) u_fake_memory (
        .clk        (clk),
        .rst        (rst),
        .bus_req    (bus_req),
        .bus_addr   (bus_addr),
        .bus_we     (bus_we),
        .bus_wdata  (bus_wdata),
        .bus_wstrb  (bus_wstrb),
        .bus_rdata  (bus_rdata),
        .bus_ready  (bus_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task for CPU Read
    task cpu_read(input [31:0] addr);
        begin
            @(posedge clk);
            cpu_req   = 1;
            cpu_addr  = addr;
            cpu_we    = 0;
            cpu_wstrb = 0;
            
            // Wait for ready
            wait(cpu_ready == 1);
            @(posedge clk);
            cpu_req = 0;
            $display("Time: %0t | READ  Addr: 0x%h | Data: 0x%h", $time, addr, cpu_rdata);
            #10;
        end
    endtask

    // Task for CPU Write
    task cpu_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
        begin
            @(posedge clk);
            cpu_req   = 1;
            cpu_addr  = addr;
            cpu_we    = 1;
            cpu_wdata = data;
            cpu_wstrb = strb;
            
            // Wait for ready
            wait(cpu_ready == 1);
            @(posedge clk);
            cpu_req = 0;
            $display("Time: %0t | WRITE Addr: 0x%h | Data: 0x%h | Strb: %b", $time, addr, data, strb);
            #10;
        end
    endtask

    initial begin
        // Initialize
        rst = 1;
        cpu_req = 0;
        cpu_addr = 0;
        cpu_we = 0;
        cpu_wdata = 0;
        cpu_wstrb = 0;
        
        #20;
        rst = 0;
        #20;
        
        $display("--- TEST 1: Cacheable Read Miss (Address 0x4000_0000) ---");
        // Should take many cycles to fetch 4 words (burst)
        cpu_read(32'h4000_0000); 
        
        $display("--- TEST 2: Cacheable Read Hit (Address 0x4000_0004) ---");
        // Should be instant (0 cycles)
        cpu_read(32'h4000_0004); 
        
        $display("--- TEST 3: Cacheable Write (Write-Through) (Address 0x4000_0008) ---");
        // Should update cache and wait for memory bus_ready
        cpu_write(32'h4000_0008, 32'hDEADBEEF, 4'b1111);
        
        $display("--- TEST 4: Read updated value (Address 0x4000_0008) ---");
        // Should be a hit, immediately return DEADBEEF
        cpu_read(32'h4000_0008); 
        
        $display("--- TEST 5: Non-Cacheable Bypass Read (UART Address 0x9000_0000) ---");
        // Should bypass cache entirely and wait for fake_memory
        cpu_read(32'h9000_0000); 
        
        $display("All tests completed!");
        $finish;
    end

endmodule
