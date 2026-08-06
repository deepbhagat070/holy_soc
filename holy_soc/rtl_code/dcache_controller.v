`timescale 1ns / 1ps

module dcache_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,       
    output wire        flush_done,  
    input  wire        cpu_req,
    input  wire [3:0]  cpu_wstrb, 
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    output reg  [31:0] cpu_rdata,
    output wire        cpu_ready, 
    output reg         bus_req,
    output reg  [3:0]  bus_wstrb, 
    output reg  [31:0] bus_addr,
    output reg  [31:0] bus_wdata,
    input  wire        bus_grant,
    input  wire        bus_ready,
    input  wire [31:0] bus_rdata
);

    wire is_cacheable = ~cpu_addr[31];

    reg [127:0] data_array  [0:255]; 
    reg [19:0]  tag_array   [0:255];
    reg         valid_array [0:255];
    reg         dirty_array [0:255]; 

    reg [127:0] data_rdata;
    reg [19:0]  tag_rdata;

    reg [19:0] req_tag_reg;
    reg [7:0]  req_index_reg;
    reg [1:0]  req_offset_reg;
    reg        is_cacheable_reg;
    reg [31:0] uncached_addr_reg;
    reg [3:0]  cpu_wstrb_reg;
    reg [31:0] cpu_wdata_reg;

    wire [19:0] req_tag    = cpu_addr[31:12];
    wire [7:0]  req_index  = cpu_addr[11:4];
    wire [1:0]  req_offset = cpu_addr[3:2]; 

    localparam IDLE          = 4'd0;
    localparam COMPARE       = 4'd1;
    localparam WB_REQ        = 4'd2;
    localparam WB_DATA       = 4'd3;
    localparam MEM_REQ       = 4'd4;
    localparam MEM_WAIT      = 4'd5;
    localparam UPDATE        = 4'd6;
    localparam UNCACHED_REQ  = 4'd7;
    localparam FLUSH_CHECK   = 4'd8;  
    localparam FLUSH_WB_REQ  = 4'd9;  
    localparam FLUSH_WB_DATA = 4'd10;

    reg [3:0] state, next_state;
    reg [1:0] burst_counter;
    reg [127:0] line_buffer;

    reg [7:0] flush_idx;
    reg       flush_done_reg;
    assign flush_done = flush_done_reg;

    wire cache_hit = valid_array[req_index_reg] && (tag_rdata == req_tag_reg);
    wire is_dirty  = dirty_array[req_index_reg];
    wire addr_unchanged = (cpu_addr[31:2] == {req_tag_reg, req_index_reg, req_offset_reg});

    assign cpu_ready = (state == COMPARE && cache_hit && is_cacheable_reg) || 
                       (state == UNCACHED_REQ && bus_ready); 

    always @(*) begin
        if (state == UNCACHED_REQ && bus_ready) begin
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

    wire [7:0] active_index = (state == UPDATE) ? req_index_reg : 
                              (state == FLUSH_CHECK || state == FLUSH_WB_REQ || state == FLUSH_WB_DATA) ? flush_idx : 
                              req_index;

    always @(posedge clk) begin
        if (state == UPDATE) begin
            data_array[req_index_reg] <= line_buffer;
            tag_array[req_index_reg]  <= req_tag_reg;
        end else if (state == COMPARE && cache_hit && is_cacheable_reg && (cpu_wstrb_reg != 4'b0000)) begin
            case (req_offset_reg)
                2'b00: begin
                    if (cpu_wstrb_reg[0]) data_array[req_index_reg][7:0]   <= cpu_wdata_reg[7:0];
                    if (cpu_wstrb_reg[1]) data_array[req_index_reg][15:8]  <= cpu_wdata_reg[15:8];
                    if (cpu_wstrb_reg[2]) data_array[req_index_reg][23:16] <= cpu_wdata_reg[23:16];
                    if (cpu_wstrb_reg[3]) data_array[req_index_reg][31:24] <= cpu_wdata_reg[31:24];
                end
                2'b01: begin
                    if (cpu_wstrb_reg[0]) data_array[req_index_reg][39:32] <= cpu_wdata_reg[7:0];
                    if (cpu_wstrb_reg[1]) data_array[req_index_reg][47:40] <= cpu_wdata_reg[15:8];
                    if (cpu_wstrb_reg[2]) data_array[req_index_reg][55:48] <= cpu_wdata_reg[23:16];
                    if (cpu_wstrb_reg[3]) data_array[req_index_reg][63:56] <= cpu_wdata_reg[31:24];
                end
                2'b10: begin
                    if (cpu_wstrb_reg[0]) data_array[req_index_reg][71:64] <= cpu_wdata_reg[7:0];
                    if (cpu_wstrb_reg[1]) data_array[req_index_reg][79:72] <= cpu_wdata_reg[15:8];
                    if (cpu_wstrb_reg[2]) data_array[req_index_reg][87:80] <= cpu_wdata_reg[23:16];
                    if (cpu_wstrb_reg[3]) data_array[req_index_reg][95:88] <= cpu_wdata_reg[31:24];
                end
                2'b11: begin
                    if (cpu_wstrb_reg[0]) data_array[req_index_reg][103:96]  <= cpu_wdata_reg[7:0];
                    if (cpu_wstrb_reg[1]) data_array[req_index_reg][111:104] <= cpu_wdata_reg[15:8];
                    if (cpu_wstrb_reg[2]) data_array[req_index_reg][119:112] <= cpu_wdata_reg[23:16];
                    if (cpu_wstrb_reg[3]) data_array[req_index_reg][127:120] <= cpu_wdata_reg[31:24];
                end
            endcase
        end

        data_rdata <= data_array[active_index];
        tag_rdata  <= tag_array[active_index];

        if (state == IDLE && cpu_req) begin
            req_tag_reg       <= req_tag;
            req_index_reg     <= req_index;
            req_offset_reg    <= req_offset;
            is_cacheable_reg  <= is_cacheable;
            uncached_addr_reg <= cpu_addr;
            cpu_wstrb_reg     <= cpu_wstrb;
            cpu_wdata_reg     <= cpu_wdata;
        end
    end

    always @(*) begin
        next_state = state;
        bus_req    = 1'b0;
        bus_wstrb  = 4'b0000;
        bus_addr   = 32'b0;
        bus_wdata  = 32'b0;

        case (state)
            IDLE: begin
                if (flush) next_state = FLUSH_CHECK;
                else if (cpu_req) next_state = COMPARE;
            end

            FLUSH_CHECK: begin
                if (valid_array[flush_idx] && dirty_array[flush_idx]) begin
                    next_state = FLUSH_WB_REQ;
                end else if (flush_idx == 8'd255) begin
                    next_state = IDLE;
                end else begin
                    next_state = FLUSH_CHECK; 
                end
            end

            FLUSH_WB_REQ: begin
                bus_req   = 1'b1;
                bus_wstrb = 4'b1111; 
                bus_addr  = {tag_rdata, flush_idx, 4'b0000}; 
                if (bus_grant) next_state = FLUSH_WB_DATA;
            end

            FLUSH_WB_DATA: begin
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_rdata, flush_idx, 4'b0000}; 
                case (burst_counter)
                    2'b00: bus_wdata = data_rdata[31:0];
                    2'b01: bus_wdata = data_rdata[63:32];
                    2'b10: bus_wdata = data_rdata[95:64];
                    2'b11: bus_wdata = data_rdata[127:96];
                endcase
                if (bus_ready && (burst_counter == 2'b11)) begin
                    if (flush_idx == 8'd255) next_state = IDLE;
                    else next_state = FLUSH_CHECK;
                end
            end

            COMPARE: begin
                if (!is_cacheable_reg) begin
                    next_state = UNCACHED_REQ;
                end else if (!cache_hit) begin
                    if (valid_array[req_index_reg] && is_dirty)
                        next_state = WB_REQ;
                    else
                        next_state = MEM_REQ;
                end else begin
                    if (cpu_req && addr_unchanged) 
                        next_state = COMPARE;
                    else 
                        next_state = IDLE;
                end
            end

            UNCACHED_REQ: begin
                bus_req   = 1'b1;
                bus_addr  = uncached_addr_reg; 
                bus_wstrb = cpu_wstrb_reg; 
                bus_wdata = cpu_wdata_reg;
                if (bus_ready) next_state = IDLE; 
            end

            WB_REQ: begin
                bus_req   = 1'b1;
                bus_wstrb = 4'b1111; 
                bus_addr  = {tag_rdata, req_index_reg, 4'b0000}; 
                if (bus_grant) next_state = WB_DATA;
            end

            WB_DATA: begin
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_rdata, req_index_reg, 4'b0000}; 
                case (burst_counter)
                    2'b00: bus_wdata = data_rdata[31:0];
                    2'b01: bus_wdata = data_rdata[63:32];
                    2'b10: bus_wdata = data_rdata[95:64];
                    2'b11: bus_wdata = data_rdata[127:96];
                endcase
                if (bus_ready && (burst_counter == 2'b11)) next_state = MEM_REQ;
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
        if (rst) begin
            state <= IDLE;
            burst_counter <= 2'b00;
            flush_idx <= 8'd0;
            flush_done_reg <= 1'b0;
            for (i = 0; i < 256; i = i + 1) begin
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end else begin
            state <= next_state; 

            if ((state == FLUSH_CHECK && !(valid_array[flush_idx] && dirty_array[flush_idx]) && flush_idx == 8'd255) ||
                (state == FLUSH_WB_DATA && bus_ready && burst_counter == 2'b11 && flush_idx == 8'd255)) begin
                flush_done_reg <= 1'b1;
            end else begin
                flush_done_reg <= 1'b0;
            end

            case (state)
                IDLE: begin
                    if (flush) flush_idx <= 8'd0;
                end
                
                FLUSH_CHECK: begin
                    if (!(valid_array[flush_idx] && dirty_array[flush_idx])) begin
                        if (flush_idx != 8'd255) flush_idx <= flush_idx + 1'b1;
                    end
                end

                FLUSH_WB_REQ, WB_REQ, MEM_REQ: begin
                    burst_counter <= 2'b00;
                end

                FLUSH_WB_DATA: begin
                    if (bus_ready) burst_counter <= burst_counter + 1'b1;
                    if (bus_ready && (burst_counter == 2'b11)) begin
                        dirty_array[flush_idx] <= 1'b0; 
                        if (flush_idx != 8'd255) flush_idx <= flush_idx + 1'b1;
                    end
                end

                WB_DATA: begin
                    if (bus_ready) burst_counter <= burst_counter + 1'b1;
                end

                COMPARE: begin
                    if (cache_hit && is_cacheable_reg && (cpu_wstrb_reg != 4'b0000)) begin
                        dirty_array[req_index_reg] <= 1'b1;
                    end
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
                    dirty_array[req_index_reg] <= 1'b0; 
                end
            endcase
        end
    end
endmodule