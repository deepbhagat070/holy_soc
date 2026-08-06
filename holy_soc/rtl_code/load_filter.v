`timescale 1ns / 1ps

module load_filter(
    input      [2:0]  funct3,       
    input      [31:0] raw_ram_out, 
    input      [1:0]  addr_align,   
    output reg [31:0] clean_data    
);

    always @(*) begin
        case (funct3)
            3'b010: clean_data = raw_ram_out; 
            
            3'b001: begin 
                case (addr_align[1]) 
                    1'b0 : clean_data = { {16{raw_ram_out[15]}}, raw_ram_out[15:0] };
                    1'b1 : clean_data = { {16{raw_ram_out[31]}}, raw_ram_out[31:16] };
                endcase
            end
            
            3'b101: begin 
                case (addr_align[1])
                    1'b0 : clean_data = { 16'b0, raw_ram_out[15:0] };
                    1'b1 : clean_data = { 16'b0, raw_ram_out[31:16] };
                endcase
            end
            
            3'b000: begin 
                case (addr_align)
                    2'b00 : clean_data = { {24{raw_ram_out[7]}},  raw_ram_out[7:0] };
                    2'b01 : clean_data = { {24{raw_ram_out[15]}}, raw_ram_out[15:8] };
                    2'b10 : clean_data = { {24{raw_ram_out[23]}}, raw_ram_out[23:16] };
                    2'b11 : clean_data = { {24{raw_ram_out[31]}}, raw_ram_out[31:24] };
                endcase
            end 
            
            3'b100: begin 
                case (addr_align)
                    2'b00 : clean_data = { 24'b0, raw_ram_out[7:0] };
                    2'b01 : clean_data = { 24'b0, raw_ram_out[15:8] };
                    2'b10 : clean_data = { 24'b0, raw_ram_out[23:16] };
                    2'b11 : clean_data = { 24'b0, raw_ram_out[31:24] };
                endcase
            end
            default: clean_data = 32'b0; 
        endcase
    end

endmodule