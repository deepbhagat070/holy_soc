`timescale 1ns / 1ps

module icache_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,

    
    input  wire        cpu_req,
    input  wire [31:0] cpu_addr,
    output reg  [31:0] cpu_rdata,
    output wire        cpu_ready,

    
    output reg         bus_req,
    output reg  [31:0] bus_addr,
    input  wire        bus_grant,
    input  wire        bus_ready,
    input  wire [31:0] bus_rdata
);

    wire is_cacheable = ~cpu_addr[31];

    
    
    
    reg [127:0] data_array  [0:255];
    reg [19:0]  tag_array   [0:255];
    reg         valid_array [0:255];

    integer j;
    initial begin
        for (j = 0; j < 256; j = j + 1) begin
            data_array[j]  = 128'b0;
            tag_array[j]   = 20'b0;
            valid_array[j] = 1'b0;
        end
    end

    
    
    
    wire [19:0] req_tag   = cpu_addr[31:12];
    wire [7:0]  req_index = cpu_addr[11:4];

    
    
    
    reg [19:0] req_tag_reg;
    reg [7:0]  req_index_reg;
    reg [1:0]  req_word_sel;
    reg        req_cacheable;
    reg [31:0] req_addr_reg;

    
    
    
    
    
    wire [19:0]  cmp_tag   = tag_array[req_index_reg];
    wire         cmp_valid = valid_array[req_index_reg];
    wire         cache_hit = cmp_valid && (cmp_tag == req_tag_reg);

    
    
    wire line_unchanged = (cpu_addr[31:4] == {req_tag_reg, req_index_reg});

    
    
    
    localparam [2:0]
        IDLE         = 3'd0,
        COMPARE      = 3'd1,
        MEM_REQ      = 3'd2,
        MEM_WAIT     = 3'd3,
        UPDATE       = 3'd4,
        UNCACHED_REQ = 3'd5,
        UNCACHED_WAIT= 3'd6;

    reg [2:0] state;

    reg [1:0]   burst_counter;
    reg [127:0] line_buffer;

    
    
    
    assign cpu_ready = (state == COMPARE && cache_hit && req_cacheable && line_unchanged) ||
                       (state == UNCACHED_WAIT && bus_ready);

    
    
    
    
    always @(*) begin
        if (state == UNCACHED_WAIT && bus_ready) begin
            cpu_rdata = bus_rdata;
        end else begin
            case (cpu_addr[3:2])
                2'b00:   cpu_rdata = data_array[req_index_reg][31:0];
                2'b01:   cpu_rdata = data_array[req_index_reg][63:32];
                2'b10:   cpu_rdata = data_array[req_index_reg][95:64];
                2'b11:   cpu_rdata = data_array[req_index_reg][127:96];
                default: cpu_rdata = 32'h00000013; 
            endcase
        end
    end

    
    
    
    always @(*) begin
        bus_req  = 1'b0;
        bus_addr = 32'b0;

        case (state)
            UNCACHED_REQ: begin
                bus_req  = 1'b1;
                bus_addr = req_addr_reg;
            end
            MEM_REQ: begin
                bus_req  = 1'b1;
                bus_addr = {req_tag_reg, req_index_reg, 4'b0000};
            end
            MEM_WAIT: begin
                bus_req  = 1'b1;  
                bus_addr = {req_tag_reg, req_index_reg, burst_counter, 2'b00};
            end
            UNCACHED_WAIT: begin
                bus_req  = 1'b1;  
                bus_addr = req_addr_reg;
            end
            default: begin end
        endcase
    end

    
    
    
    integer i;
    always @(posedge clk) begin
        if (rst || flush) begin
            state         <= IDLE;
            burst_counter <= 2'b00;
            for (i = 0; i < 256; i = i + 1)
                valid_array[i] <= 1'b0;
        end else begin

            case (state)

                
                IDLE: begin
                    if (cpu_req) begin
                        req_tag_reg   <= req_tag;
                        req_index_reg <= req_index;
                        req_word_sel  <= cpu_addr[3:2];
                        req_cacheable <= is_cacheable;
                        req_addr_reg  <= cpu_addr;
                        state         <= COMPARE;
                    end
                end

                
                COMPARE: begin
                    if (!req_cacheable) begin
                        state <= UNCACHED_REQ;
                    end else if (cache_hit) begin
                        
                        
                        
                        if (cpu_req && line_unchanged) begin
                            
                            state <= COMPARE;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        
                        burst_counter <= 2'b00;
                        state         <= MEM_REQ;
                    end
                end

                
                UNCACHED_REQ: begin
                    if (bus_grant) state <= UNCACHED_WAIT;
                end

                
                UNCACHED_WAIT: begin
                    if (bus_ready) state <= IDLE;
                end

                
                MEM_REQ: begin
                    burst_counter <= 2'b00;
                    if (bus_grant) state <= MEM_WAIT;
                end

                
                MEM_WAIT: begin
                    if (bus_ready) begin
                        case (burst_counter)
                            2'b00: line_buffer[31:0]   <= bus_rdata;
                            2'b01: line_buffer[63:32]  <= bus_rdata;
                            2'b10: line_buffer[95:64]  <= bus_rdata;
                            2'b11: line_buffer[127:96] <= bus_rdata;
                        endcase
                        burst_counter <= burst_counter + 1'b1;
                        if (burst_counter == 2'b11)
                            state <= UPDATE;
                    end
                end

                
                UPDATE: begin
                    data_array[req_index_reg]  <= line_buffer;
                    tag_array[req_index_reg]   <= req_tag_reg;
                    valid_array[req_index_reg] <= 1'b1;
                    state <= COMPARE; 
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule