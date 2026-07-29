`timescale 1ns / 1ps

module soc_top (
    input  clk,
    input  rst,
    output uart_tx
);

    wire [31:0] cpu_dmem_addr;
    wire [31:0] cpu_dmem_wdata;
    wire [3:0]  cpu_dmem_wstrb;
    wire        cpu_dmem_read_en;
    reg  [31:0] cpu_dmem_rdata;
    wire        cpu_dmem_ready;

    wire sel_ram  = (cpu_dmem_addr[31:28] == 4'h2);
    wire sel_uart = (cpu_dmem_addr[31:28] == 4'h4);
    wire sel_aes  = (cpu_dmem_addr[31:28] == 4'h5);

    wire [31:0] ram_rdata;
    wire [31:0] aes_rdata;
    wire        uart_ready;
    wire        aes_ready;

    always @(*) begin
        if (sel_ram) begin
            cpu_dmem_rdata = ram_rdata;
        end else if (sel_aes) begin
            cpu_dmem_rdata = aes_rdata;
        end else begin
            cpu_dmem_rdata = 32'b0;
        end
    end

    assign cpu_dmem_ready = sel_uart ? uart_ready :
                            sel_aes  ? aes_ready  :
                            1'b1;

    top_pipelined my_cpu (
        .clk(clk),
        .rst(rst),
        .dmem_ready(cpu_dmem_ready),
        .dmem_addr(cpu_dmem_addr),
        .dmem_wdata(cpu_dmem_wdata),
        .dmem_wstrb(cpu_dmem_wstrb),
        .dmem_read_en(cpu_dmem_read_en),
        .dmem_rdata(cpu_dmem_rdata)
    );

    wire [3:0] ram_wstrb = sel_ram ? cpu_dmem_wstrb : 4'b0000;
    wire ram_read_en = sel_ram ? cpu_dmem_read_en : 1'b0;
    
    data_mem my_ram (
        .clk(clk),
        .mem_read(ram_read_en),
        .we(ram_wstrb),
        .addr(cpu_dmem_addr & 32'h0000FFFF),
        .write_data(cpu_dmem_wdata),
        .read_data(ram_rdata)
    );

    wire cpu_is_writing = (cpu_dmem_wstrb != 4'b0000);

    uart_wrapper my_uart_accel (
        .clk(clk),
        .rst(rst),
        .sel(sel_uart),
        .wr_en(cpu_is_writing),
        .wdata(cpu_dmem_wdata),
        .wstrb(cpu_dmem_wstrb),
        .ready(uart_ready),
        .tx(uart_tx)
    );

    aes_wrapper my_aes_accel (
        .clk(clk),
        .rst(rst),
        .sel(sel_aes),
        .wr_en(cpu_is_writing),
        .rd_en(1'b1),
        .addr(cpu_dmem_addr[7:0]),
        .wdata(cpu_dmem_wdata),
        .rdata(aes_rdata),
        .ready(aes_ready)
    );

endmodule