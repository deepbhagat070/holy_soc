`timescale 1ns / 1ps

module boot_rom (
    input  wire        clk,
    input  wire        rst,
    input  wire        req,
    input  wire [31:0] addr,
    output reg         ready,
    output reg  [31:0] rdata
);

    reg [31:0] rom [0:255]; // 1KB Boot ROM

    initial begin
        $readmemh("bootloader.hex", rom);
    end

    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b0;
            rdata <= 32'b0;
        end else begin
            if (req) begin
                rdata <= rom[addr[9:2]];
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

endmodule
