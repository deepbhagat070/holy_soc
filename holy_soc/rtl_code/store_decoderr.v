`timescale 1ns / 1ps

module store_decoder(
    input             mem_MemWrite, 
    input      [2:0]  funct3,       
    input      [1:0]  addr_align,   
    input      [31:0] rs2_data,     
    output reg [3:0]  we_map,       
    output reg [31:0] shifted_wdata 
);

    always @(*) begin
        if (mem_MemWrite == 1'b0) begin 
            we_map = 4'b0000; 
            shifted_wdata = 32'b0;
        end else begin 
            case (funct3)
                3'b010: begin 
                    we_map = 4'b1111; 
                    shifted_wdata = rs2_data;
                end
                3'b001: begin 
                    case (addr_align[1])
                        1'b0 : begin we_map = 4'b0011; shifted_wdata = rs2_data; end
                        1'b1 : begin we_map = 4'b1100; shifted_wdata = rs2_data << 16; end
                    endcase
                end
                3'b000: begin 
                    case (addr_align)
                        2'b00 : begin we_map = 4'b0001; shifted_wdata = rs2_data; end
                        2'b01 : begin we_map = 4'b0010; shifted_wdata = rs2_data << 8; end
                        2'b10 : begin we_map = 4'b0100; shifted_wdata = rs2_data << 16; end
                        2'b11 : begin we_map = 4'b1000; shifted_wdata = rs2_data << 24; end
                    endcase
                end
                default: begin 
                    we_map = 4'b0000; 
                    shifted_wdata = 32'b0;
                end
            endcase
        end
    end

endmodule