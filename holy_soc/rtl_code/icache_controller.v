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
    reg [127:0] data_rdata;
    reg [19:0]  tag_rdata;
    reg [19:0] req_tag_reg;
    reg [7:0]  req_index_reg;
    reg [1:0]  req_offset_reg;
    reg        is_cacheable_reg;
    reg [31:0] uncached_addr_reg;

    wire [19:0] req_tag    = cpu_addr[31:12];
    wire [7:0]  req_index  = cpu_addr[11:4];
    wire [1:0]  req_offset = cpu_addr[3:2]; 
    wire addr_unchanged = (cpu_addr[31:2] == {req_tag_reg, req_index_reg, req_offset_reg}); //new

    localparam IDLE          = 3'd0;
    localparam COMPARE       = 3'd1;
    localparam MEM_REQ       = 3'd2;
    localparam MEM_WAIT      = 3'd3;
    localparam UPDATE        = 3'd4;
    localparam UNCACHED_REQ  = 3'd5;
    localparam UNCACHED_WAIT = 3'd6;

    reg [2:0] state, next_state;
    reg [1:0] burst_counter;
    reg [127:0] line_buffer;

    wire cache_hit = valid_array[req_index_reg] && (tag_rdata == req_tag_reg);

    assign cpu_ready = (state == COMPARE && cache_hit && is_cacheable_reg) || 
                       (state == UNCACHED_WAIT && bus_ready);

    always @(*) begin
        if (state == UNCACHED_WAIT && bus_ready) begin
            cpu_rdata = bus_rdata; 
        end else begin
            case (req_offset_reg)
                2'b00: cpu_rdata = data_rdata[31:0];
                2'b01: cpu_rdata = data_rdata[63:32];
                2'b10: cpu_rdata = data_rdata[95:64];
                2'b11: cpu_rdata = data_rdata[127:96];
            endcase
        end
    end

    wire [7:0] active_index = (state == UPDATE) ? req_index_reg : req_index;
    
    always @(posedge clk) begin
        if (state == UPDATE) begin
            data_array[req_index_reg] <= line_buffer;
            tag_array[req_index_reg]  <= req_tag_reg;
        end
        data_rdata <= data_array[active_index];
        tag_rdata  <= tag_array[active_index];
        
        if (state == IDLE && cpu_req) begin
            req_tag_reg       <= req_tag;
            req_index_reg     <= req_index;
            req_offset_reg    <= req_offset;
            is_cacheable_reg  <= is_cacheable;
            uncached_addr_reg <= cpu_addr;
        end
    end

    always @(*) begin
        next_state = state;
        bus_req    = 1'b0;
        bus_addr   = 32'b0;

        case (state)
            IDLE: begin
                if (cpu_req) next_state = COMPARE;
            end

            COMPARE: begin
                if (!is_cacheable_reg) begin
                    next_state = UNCACHED_REQ;
                end else if (cache_hit) begin
                    if (cpu_req && addr_unchanged) 
                        next_state = COMPARE;
                    else 
                        next_state = IDLE;
                end else begin
                    next_state = MEM_REQ;
                end
            end

            UNCACHED_REQ: begin
                bus_req  = 1'b1;
                bus_addr = uncached_addr_reg; 
                if (bus_grant) next_state = UNCACHED_WAIT;
            end

            UNCACHED_WAIT: begin
                if (bus_ready) next_state = IDLE;
            end

            MEM_REQ: begin
                bus_req  = 1'b1;
                bus_addr = {req_tag_reg, req_index_reg, 4'b0000};
                if (bus_grant) next_state = MEM_WAIT;
            end

            MEM_WAIT: begin
                if (bus_ready && (burst_counter == 2'b11)) next_state = UPDATE;
            end

            UPDATE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    integer i;
    always @(posedge clk) begin
        if (rst || flush) begin
            state <= IDLE;
            burst_counter <= 2'b00;
            for (i = 0; i < 256; i = i + 1) begin
                valid_array[i] <= 1'b0;
            end
        end else begin
            state <= next_state;
            
            case (state)
                MEM_REQ: begin
                    burst_counter <= 2'b00;
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
                    end
                end

                UPDATE: begin
                    valid_array[req_index_reg] <= 1'b1;
                end
            endcase
        end
    end
endmodule