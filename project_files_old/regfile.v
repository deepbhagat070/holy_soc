module regfile(
    input wire clk,
    input wire we,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] write_data,
    
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    // The 32 physical registers
    reg [31:0] registers [31:0];

    // Simulator cleanup: Initializes all registers to 0 at boot
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    // Asynchronous Read (x0 is always 0 + Read-After-Write Forwarding)
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 :
                      (we && (rs1_addr == rd_addr)) ? write_data : 
                      registers[rs1_addr];

    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 :
                      (we && (rs2_addr == rd_addr)) ? write_data : 
                      registers[rs2_addr];

    // Synchronous Write (Strictly Protects x0 from being overwritten)
    always @(posedge clk) begin
        if (we && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= write_data;
        end
    end

endmodule