`timescale 1ns / 1ps

module main_memory (
    input  wire        clk,
    input  wire        rst,
    input  wire        mem_bus_req,
    input  wire [31:0] mem_bus_addr,
    input  wire [31:0] mem_bus_wdata,
    input  wire [3:0]  mem_bus_wstrb,
    output wire        mem_bus_grant,
    output reg         mem_bus_ready,
    output reg  [31:0] mem_bus_rdata
);
    reg [31:0] ram [0:16383];
    integer i;

    initial begin
        for (i = 0; i < 16384; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
        $readmemh("C:/Users/Admin/Desktop/Internship_prep/firmware/program.txt", ram);
    end

    assign mem_bus_grant = mem_bus_req; 
    reg [31:0] active_addr;
    reg [2:0]  beat_cnt;
    reg        is_active;
    always @(posedge clk) begin
        if (rst) begin
            is_active     <= 1'b0;
            mem_bus_ready <= 1'b0;
            beat_cnt      <= 3'd0;
        end else begin
            mem_bus_ready <= 1'b0;
            if (!is_active && mem_bus_req) begin
                is_active   <= 1'b1;
                active_addr <= mem_bus_addr;
                beat_cnt    <= 3'd0;
            end else if (is_active) begin
                if (mem_bus_wstrb[0]) ram[active_addr[15:2]][7:0]   <= mem_bus_wdata[7:0];
                if (mem_bus_wstrb[1]) ram[active_addr[15:2]][15:8]  <= mem_bus_wdata[15:8];
                if (mem_bus_wstrb[2]) ram[active_addr[15:2]][23:16] <= mem_bus_wdata[23:16];
                if (mem_bus_wstrb[3]) ram[active_addr[15:2]][31:24] <= mem_bus_wdata[31:24];
                mem_bus_rdata <= ram[active_addr[15:2]];
                mem_bus_ready <= 1'b1;
                active_addr <= {active_addr[31:2] + 1'b1, 2'b00};
                beat_cnt    <= beat_cnt + 1'b1;
                if ((~active_addr[31] && beat_cnt == 3'd3) || (active_addr[31] && beat_cnt == 3'd0)) begin
                    is_active <= 1'b0;
                end
            end
        end
    end
endmodule