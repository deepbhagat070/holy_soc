`timescale 1ns / 1ps

module cache_bram_128 (
    input  wire         clk,
    input  wire [7:0]   addr,
    input  wire [15:0]  we,
    input  wire [127:0] din,
    output reg  [127:0] dout
);

    (* ram_style = "block" *) reg [127:0] ram [0:255];

    always @(posedge clk) begin
        if (we[0])  ram[addr][7:0]     <= din[7:0];
        if (we[1])  ram[addr][15:8]    <= din[15:8];
        if (we[2])  ram[addr][23:16]   <= din[23:16];
        if (we[3])  ram[addr][31:24]   <= din[31:24];
        if (we[4])  ram[addr][39:32]   <= din[39:32];
        if (we[5])  ram[addr][47:40]   <= din[47:40];
        if (we[6])  ram[addr][55:48]   <= din[55:48];
        if (we[7])  ram[addr][63:56]   <= din[63:56];
        if (we[8])  ram[addr][71:64]   <= din[71:64];
        if (we[9])  ram[addr][79:72]   <= din[79:72];
        if (we[10]) ram[addr][87:80]   <= din[87:80];
        if (we[11]) ram[addr][95:88]   <= din[95:88];
        if (we[12]) ram[addr][103:96]  <= din[103:96];
        if (we[13]) ram[addr][111:104] <= din[111:104];
        if (we[14]) ram[addr][119:112] <= din[119:112];
        if (we[15]) ram[addr][127:120] <= din[127:120];

        // WRITE_FIRST bypass logic
        dout[7:0]     <= we[0]  ? din[7:0]     : ram[addr][7:0];
        dout[15:8]    <= we[1]  ? din[15:8]    : ram[addr][15:8];
        dout[23:16]   <= we[2]  ? din[23:16]   : ram[addr][23:16];
        dout[31:24]   <= we[3]  ? din[31:24]   : ram[addr][31:24];
        dout[39:32]   <= we[4]  ? din[39:32]   : ram[addr][39:32];
        dout[47:40]   <= we[5]  ? din[47:40]   : ram[addr][47:40];
        dout[55:48]   <= we[6]  ? din[55:48]   : ram[addr][55:48];
        dout[63:56]   <= we[7]  ? din[63:56]   : ram[addr][63:56];
        dout[71:64]   <= we[8]  ? din[71:64]   : ram[addr][71:64];
        dout[79:72]   <= we[9]  ? din[79:72]   : ram[addr][79:72];
        dout[87:80]   <= we[10] ? din[87:80]   : ram[addr][87:80];
        dout[95:88]   <= we[11] ? din[95:88]   : ram[addr][95:88];
        dout[103:96]  <= we[12] ? din[103:96]  : ram[addr][103:96];
        dout[111:104] <= we[13] ? din[111:104] : ram[addr][111:104];
        dout[119:112] <= we[14] ? din[119:112] : ram[addr][119:112];
        dout[127:120] <= we[15] ? din[127:120] : ram[addr][127:120];
    end
endmodule