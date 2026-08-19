`timescale 1ns / 1ps

module dcache_controller (
    input  wire        clk,
    input  wire        rst,

    
    input  wire        flush,
    output reg         flush_done,

    
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

    
    
    
    wire is_cacheable_in = ~cpu_addr[31];

    
    
    
    reg [127:0] data_array  [0:255];
    reg [19:0]  tag_array   [0:255];
    reg         valid_array [0:255];
    reg         dirty_array [0:255];

    integer j;
    initial begin
        for (j = 0; j < 256; j = j + 1) begin
            data_array[j]  = 128'b0;
            tag_array[j]   = 20'b0;
            valid_array[j] = 1'b0;
            dirty_array[j] = 1'b0;
        end
    end

    
    
    
    reg [31:0] req_addr_reg;    
    reg [19:0] req_tag_reg;
    reg [7:0]  req_index_reg;
    reg [1:0]  req_word_sel;    
    reg        req_cacheable;
    reg [3:0]  req_wstrb_reg;
    reg [31:0] req_wdata_reg;

    wire [19:0] cur_tag   = cpu_addr[31:12];
    wire [7:0]  cur_index = cpu_addr[11:4];

    
    
    
    localparam [3:0]
        IDLE          = 4'd0,
        COMPARE       = 4'd1,
        WB_REQ        = 4'd2,
        WB_DATA       = 4'd3,
        MEM_REQ       = 4'd4,
        MEM_WAIT      = 4'd5,
        UPDATE        = 4'd6,
        UNCACHED_REQ  = 4'd7,
        FLUSH_CHECK   = 4'd8,
        FLUSH_WB_REQ  = 4'd9,
        FLUSH_WB_DATA = 4'd10,
        UNCACHED_WAIT = 4'd11;

    reg [3:0] state;

    
    
    
    reg [1:0]   burst_counter;
    reg [127:0] line_buffer;

    
    
    
    reg [7:0] flush_idx;

    
    
    
    wire cache_hit = valid_array[req_index_reg] &&
                     (tag_array[req_index_reg] == req_tag_reg);
    wire is_dirty  = dirty_array[req_index_reg];

    
    
    
    
    
    assign cpu_ready = (state == COMPARE && cache_hit && req_cacheable) ||
                       (state == UNCACHED_REQ && bus_ready);

    
    
    
    
    
    

    
    
    reg [127:0] fwd_line;
    always @(*) begin
        fwd_line = data_array[req_index_reg];
        if (state == COMPARE && cache_hit && req_cacheable && (cpu_wstrb != 4'b0)) begin
            case (cpu_addr[3:2])
                2'b00: begin
                    if (cpu_wstrb[0]) fwd_line[7:0]    = cpu_wdata[7:0];
                    if (cpu_wstrb[1]) fwd_line[15:8]   = cpu_wdata[15:8];
                    if (cpu_wstrb[2]) fwd_line[23:16]  = cpu_wdata[23:16];
                    if (cpu_wstrb[3]) fwd_line[31:24]  = cpu_wdata[31:24];
                end
                2'b01: begin
                    if (cpu_wstrb[0]) fwd_line[39:32]  = cpu_wdata[7:0];
                    if (cpu_wstrb[1]) fwd_line[47:40]  = cpu_wdata[15:8];
                    if (cpu_wstrb[2]) fwd_line[55:48]  = cpu_wdata[23:16];
                    if (cpu_wstrb[3]) fwd_line[63:56]  = cpu_wdata[31:24];
                end
                2'b10: begin
                    if (cpu_wstrb[0]) fwd_line[71:64]  = cpu_wdata[7:0];
                    if (cpu_wstrb[1]) fwd_line[79:72]  = cpu_wdata[15:8];
                    if (cpu_wstrb[2]) fwd_line[87:80]  = cpu_wdata[23:16];
                    if (cpu_wstrb[3]) fwd_line[95:88]  = cpu_wdata[31:24];
                end
                2'b11: begin
                    if (cpu_wstrb[0]) fwd_line[103:96]  = cpu_wdata[7:0];
                    if (cpu_wstrb[1]) fwd_line[111:104] = cpu_wdata[15:8];
                    if (cpu_wstrb[2]) fwd_line[119:112] = cpu_wdata[23:16];
                    if (cpu_wstrb[3]) fwd_line[127:120] = cpu_wdata[31:24];
                end
            endcase
        end
    end

    always @(*) begin
        if (state == UNCACHED_REQ && bus_ready)
            cpu_rdata = bus_rdata;
        else begin
            case (req_word_sel)
                2'b00:   cpu_rdata = fwd_line[31:0];
                2'b01:   cpu_rdata = fwd_line[63:32];
                2'b10:   cpu_rdata = fwd_line[95:64];
                2'b11:   cpu_rdata = fwd_line[127:96];
                default: cpu_rdata = 32'b0;
            endcase
        end
    end

    
    
    
    always @(*) begin
        bus_req   = 1'b0;
        bus_wstrb = 4'b0000;
        bus_addr  = 32'b0;
        bus_wdata = 32'b0;

        case (state)
            
            UNCACHED_REQ, UNCACHED_WAIT: begin
                bus_req   = 1'b1;
                bus_addr  = req_addr_reg;
                bus_wstrb = req_wstrb_reg;
                bus_wdata = req_wdata_reg;
            end

            
            WB_REQ: begin
                bus_req   = 1'b1;
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_array[req_index_reg], req_index_reg, 4'b0000};
                bus_wdata = data_array[req_index_reg][31:0];
            end

            
            WB_DATA: begin
                bus_req   = 1'b1;  
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_array[req_index_reg], req_index_reg,
                             burst_counter, 2'b00};
                case (burst_counter + bus_ready)
                    2'b00: bus_wdata = data_array[req_index_reg][31:0];
                    2'b01: bus_wdata = data_array[req_index_reg][63:32];
                    2'b10: bus_wdata = data_array[req_index_reg][95:64];
                    2'b11: bus_wdata = data_array[req_index_reg][127:96];
                    default: bus_wdata = data_array[req_index_reg][127:96]; 
                endcase
            end

            
            MEM_REQ: begin
                bus_req  = 1'b1;
                bus_addr = {req_tag_reg, req_index_reg, 4'b0000};
            end

            
            MEM_WAIT: begin
                bus_req  = 1'b1;  
                bus_addr = {req_tag_reg, req_index_reg, burst_counter, 2'b00};
            end

            
            FLUSH_WB_REQ: begin
                bus_req   = 1'b1;
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_array[flush_idx], flush_idx, 4'b0000};
                bus_wdata = data_array[flush_idx][31:0];
            end

            
            FLUSH_WB_DATA: begin
                bus_req   = 1'b1;  
                bus_wstrb = 4'b1111;
                bus_addr  = {tag_array[flush_idx], flush_idx,
                             burst_counter, 2'b00};
                
                case (burst_counter + bus_ready)
                    2'b00: bus_wdata = data_array[flush_idx][31:0];
                    2'b01: bus_wdata = data_array[flush_idx][63:32];
                    2'b10: bus_wdata = data_array[flush_idx][95:64];
                    2'b11: bus_wdata = data_array[flush_idx][127:96];
                    default: bus_wdata = data_array[flush_idx][127:96]; 
                endcase
            end

            default: begin  end
        endcase
    end

    
    
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            burst_counter <= 2'b00;
            flush_idx     <= 8'd0;
            flush_done    <= 1'b0;
            for (i = 0; i < 256; i = i + 1) begin
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end else begin

            
            flush_done <= 1'b0;

            case (state)

                
                IDLE: begin
                    if (flush) begin
                        flush_idx <= 8'd0;
                        state     <= FLUSH_CHECK;
                    end else if (cpu_req) begin
                        
                        req_addr_reg  <= cpu_addr;
                        req_tag_reg   <= cur_tag;
                        req_index_reg <= cur_index;
                        req_word_sel  <= cpu_addr[3:2];
                        req_cacheable <= is_cacheable_in;
                        req_wstrb_reg <= cpu_wstrb;
                        req_wdata_reg <= cpu_wdata;
                        state         <= COMPARE;
                    end
                end

                
                COMPARE: begin
                    if (!req_cacheable) begin
                        
                        state <= UNCACHED_REQ;

                    end else if (cache_hit) begin
                        
                        
                        if (cpu_wstrb != 4'b0) begin
                            dirty_array[req_index_reg] <= 1'b1;
                            case (cpu_addr[3:2])
                                2'b00: begin
                                    if (cpu_wstrb[0]) data_array[req_index_reg][7:0]    <= cpu_wdata[7:0];
                                    if (cpu_wstrb[1]) data_array[req_index_reg][15:8]   <= cpu_wdata[15:8];
                                    if (cpu_wstrb[2]) data_array[req_index_reg][23:16]  <= cpu_wdata[23:16];
                                    if (cpu_wstrb[3]) data_array[req_index_reg][31:24]  <= cpu_wdata[31:24];
                                end
                                2'b01: begin
                                    if (cpu_wstrb[0]) data_array[req_index_reg][39:32]  <= cpu_wdata[7:0];
                                    if (cpu_wstrb[1]) data_array[req_index_reg][47:40]  <= cpu_wdata[15:8];
                                    if (cpu_wstrb[2]) data_array[req_index_reg][55:48]  <= cpu_wdata[23:16];
                                    if (cpu_wstrb[3]) data_array[req_index_reg][63:56]  <= cpu_wdata[31:24];
                                end
                                2'b10: begin
                                    if (cpu_wstrb[0]) data_array[req_index_reg][71:64]  <= cpu_wdata[7:0];
                                    if (cpu_wstrb[1]) data_array[req_index_reg][79:72]  <= cpu_wdata[15:8];
                                    if (cpu_wstrb[2]) data_array[req_index_reg][87:80]  <= cpu_wdata[23:16];
                                    if (cpu_wstrb[3]) data_array[req_index_reg][95:88]  <= cpu_wdata[31:24];
                                end
                                2'b11: begin
                                    if (cpu_wstrb[0]) data_array[req_index_reg][103:96]  <= cpu_wdata[7:0];
                                    if (cpu_wstrb[1]) data_array[req_index_reg][111:104] <= cpu_wdata[15:8];
                                    if (cpu_wstrb[2]) data_array[req_index_reg][119:112] <= cpu_wdata[23:16];
                                    if (cpu_wstrb[3]) data_array[req_index_reg][127:120] <= cpu_wdata[31:24];
                                end
                            endcase
                        end
                        
                        
                        state <= IDLE;

                    end else begin
                        
                        if (valid_array[req_index_reg] && is_dirty) begin
                            
                            burst_counter <= 2'b00;
                            state         <= WB_REQ;
                        end else begin
                            
                            burst_counter <= 2'b00;
                            state         <= MEM_REQ;
                        end
                    end
                end

                
                UNCACHED_REQ: begin
                    
                    
                    if (bus_ready) begin
                        state <= IDLE;
                    end
                end

                
                WB_REQ: begin
                    
                    burst_counter <= 2'b00;
                    if (bus_grant) state <= WB_DATA;
                end

                
                WB_DATA: begin
                    if (bus_ready) begin
                        burst_counter <= burst_counter + 1'b1;
                        if (burst_counter == 2'b11) begin
                            dirty_array[req_index_reg] <= 1'b0;
                            burst_counter              <= 2'b00;
                            state                      <= MEM_REQ;
                        end
                    end
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
                        if (burst_counter == 2'b11) begin
                            state <= UPDATE;
                        end
                    end
                end

                
                UPDATE: begin
                    
                    if (cpu_req) begin
                        state <= COMPARE;
                        req_word_sel  <= cpu_addr[3:2];
                        req_wstrb_reg <= cpu_wstrb;
                        req_wdata_reg <= cpu_wdata;
                        req_cacheable <= is_cacheable_in;
                    end else begin
                        state <= IDLE;
                    end
                    data_array[req_index_reg]  <= line_buffer;
                    tag_array[req_index_reg]   <= req_tag_reg;
                    valid_array[req_index_reg] <= 1'b1;
                    dirty_array[req_index_reg] <= 1'b0;
                end

                
                FLUSH_CHECK: begin
                    if (valid_array[flush_idx] && dirty_array[flush_idx]) begin
                        burst_counter <= 2'b00;
                        state         <= FLUSH_WB_REQ;
                    end else begin
                        if (flush_idx == 8'd255) begin
                            flush_done <= 1'b1;
                            state      <= IDLE;
                        end else begin
                            flush_idx <= flush_idx + 1'b1;
                            
                        end
                    end
                end

                
                FLUSH_WB_REQ: begin
                    burst_counter <= 2'b00;
                    if (bus_grant) state <= FLUSH_WB_DATA;
                end

                
                FLUSH_WB_DATA: begin
                    if (bus_ready) begin
                        burst_counter <= burst_counter + 1'b1;
                        if (burst_counter == 2'b11) begin
                            dirty_array[flush_idx] <= 1'b0;
                            if (flush_idx == 8'd255) begin
                                flush_done <= 1'b1;
                                state      <= IDLE;
                            end else begin
                                flush_idx <= flush_idx + 1'b1;
                                state     <= FLUSH_CHECK;
                            end
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule