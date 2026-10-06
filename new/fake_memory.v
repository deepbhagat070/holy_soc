`timescale 1ns / 1ps

module fake_memory #(
    parameter LATENCY = 3 // Programmable latency in clock cycles
) (
    input wire clk,
    input wire rst,

    input  wire        bus_req,
    input  wire [31:0] bus_addr,
    input  wire        bus_we,
    input  wire [31:0] bus_wdata,
    input  wire [3:0]  bus_wstrb,
    
    output reg  [31:0] bus_rdata,
    output reg         bus_ready
);

    // 64KB RAM (Word addressed)
    reg [31:0] ram [0:16383]; 
    
    integer i;
    initial begin
        for(i = 0; i < 16384; i = i + 1) begin
            ram[i] = i; // Recognizable pattern for debugging cache fills
        end
    end

    reg [3:0] timer;
    reg active;
    
    always @(posedge clk) begin
        if (rst) begin
            timer <= 0;
            active <= 0;
            bus_ready <= 0;
            bus_rdata <= 0;
        end else begin
            if (bus_req && !active && !bus_ready) begin
                active <= 1'b1;
                timer <= LATENCY[3:0];
            end else if (active) begin
                if (timer > 0) begin
                    timer <= timer - 1;
                end else begin
                    // Timer finished, perform memory operation
                    active <= 1'b0;
                    bus_ready <= 1'b1;
                    
                    if (bus_we) begin
                        if (bus_wstrb[0]) ram[bus_addr[31:2]][7:0]   <= bus_wdata[7:0];
                        if (bus_wstrb[1]) ram[bus_addr[31:2]][15:8]  <= bus_wdata[15:8];
                        if (bus_wstrb[2]) ram[bus_addr[31:2]][23:16] <= bus_wdata[23:16];
                        if (bus_wstrb[3]) ram[bus_addr[31:2]][31:24] <= bus_wdata[31:24];
                    end else begin
                        bus_rdata <= ram[bus_addr[31:2]];
                    end
                end
            end else if (bus_ready) begin
                // Deassert bus_ready after 1 clock cycle
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
