`timescale 1ns / 1ps

module pc(
    input clk,
    input rst,
    input [31:0] pc_next,
    input pc_write,
    input en,
    output reg [31:0] pc
);
    always@(posedge clk) begin
        if (rst) begin
            pc <= 32'b0;
        end 
        // CHANGED: Your existing code had `pc_write & en`. Ensure `pc_en` from the HDU is explicitly routed to this `en` port in your top module so it halts on load-use hazards.[cite: 9]
        else if (pc_write & en) begin
            pc <= pc_next;
        end
     end
endmodule