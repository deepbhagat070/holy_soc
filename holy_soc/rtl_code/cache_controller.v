`timescale 1ns / 1ps

module cache_controller (
    input  wire        clk,
    input  wire        rst,

    // CPU Interface
    input  wire        cpu_req,
    input  wire [3:0]  cpu_wstrb, 
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    output reg  [31:0] cpu_rdata,
    output wire        cpu_ready, 

    // Main Memory/Bus Arbiter Interface
    output reg         bus_req,
    output reg         bus_we,
    output reg  [31:0] bus_addr,
    output reg  [31:0] bus_wdata,
    input  wire        bus_grant,
    input  wire        bus_ready,
    input  wire [31:0] bus_rdata
);

    // --- Cache Storage Arrays ---
    reg [127:0] data_array  [0:255]; 
    reg [19:0]  tag_array   [0:255];
    reg         valid_array [0:255];
    reg         dirty_array [0:255]; // Track modified lines

    // --- Address Decoding ---
    wire [19:0] req_tag    = cpu_addr[31:12];
    wire [7:0]  req_index  = cpu_addr[11:4];
    wire [1:0]  req_offset = cpu_addr[3:2]; 

    // --- Hit & Dirty Detection ---
    wire cache_hit = valid_array[req_index] && (tag_array[req_index] == req_tag);
    wire is_dirty  = dirty_array[req_index];

    // --- FSM States ---
    localparam COMPARE  = 3'd0;
    localparam WB_REQ   = 3'd1;
    localparam WB_DATA  = 3'd2;
    localparam MEM_REQ  = 3'd3;
    localparam MEM_WAIT = 3'd4;
    localparam UPDATE   = 3'd5;

    reg [2:0] state, next_state;
    reg [1:0] burst_counter;
    reg [127:0] line_buffer;

    // --- CPU Ready Signal ---
    assign cpu_ready = (state == COMPARE) && cpu_req && cache_hit;

    // --- Continuous Read Logic ---
    always @(*) begin
        case (req_offset)
            2'b00: cpu_rdata = data_array[req_index][31:0];
            2'b01: cpu_rdata = data_array[req_index][63:32];
            2'b10: cpu_rdata = data_array[req_index][95:64];
            2'b11: cpu_rdata = data_array[req_index][127:96];
        endcase
    end

    // --- FSM State Register ---
    always @(posedge clk) begin
        if (rst) state <= COMPARE;
        else     state <= next_state;
    end

    // --- FSM Next-State & Bus Logic (Combinational) ---
    always @(*) begin
        next_state = state;
        bus_req    = 1'b0;
        bus_we     = 1'b0;
        bus_addr   = 32'b0;
        bus_wdata  = 32'b0;

        case (state)
            COMPARE: begin
                if (cpu_req && !cache_hit) begin
                    if (valid_array[req_index] && is_dirty)
                        next_state = WB_REQ;
                    else
                        next_state = MEM_REQ;
                end
            end

            WB_REQ: begin
                bus_req  = 1'b1;
                bus_we   = 1'b1;
                // Reconstruct the physical address of the evicted block
                bus_addr = {tag_array[req_index], req_index, 4'b0000}; 
                if (bus_grant) begin
                    next_state = WB_DATA;
                end
            end

            WB_DATA: begin
                bus_we   = 1'b1;
                bus_addr = {tag_array[req_index], req_index, 4'b0000}; 
                
                // Multiplex the 128-bit block out to the 32-bit bus
                case (burst_counter)
                    2'b00: bus_wdata = data_array[req_index][31:0];
                    2'b01: bus_wdata = data_array[req_index][63:32];
                    2'b10: bus_wdata = data_array[req_index][95:64];
                    2'b11: bus_wdata = data_array[req_index][127:96];
                endcase

                if (bus_ready && (burst_counter == 2'b11)) begin
                    next_state = MEM_REQ;
                end
            end

            MEM_REQ: begin
                bus_req  = 1'b1;
                bus_addr = {cpu_addr[31:4], 4'b0000};
                if (bus_grant) begin
                    next_state = MEM_WAIT;
                end
            end

            MEM_WAIT: begin
                if (bus_ready && (burst_counter == 2'b11)) begin
                    next_state = UPDATE;
                end
            end

            UPDATE: begin
                next_state = COMPARE;
            end
            
            default: next_state = COMPARE;
        endcase
    end

    // --- Datapath and Array Updates (Sequential) ---
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            burst_counter <= 2'b00;
            // NOTE: Loop initialization of SRAM arrays is for simulation/FPGA inference.
            // ASIC standard practice requires a dedicated hardware flush state machine.
            for (i = 0; i < 256; i = i + 1) begin
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end else begin
            case (state)
                COMPARE: begin
                    if (cpu_req && cache_hit && (cpu_wstrb != 4'b0000)) begin
                        // Write hit updates local SRAM and flags block as dirty
                        dirty_array[req_index] <= 1'b1;
                        case (req_offset)
                            2'b00: begin
                                if (cpu_wstrb[0]) data_array[req_index][7:0]   <= cpu_wdata[7:0];
                                if (cpu_wstrb[1]) data_array[req_index][15:8]  <= cpu_wdata[15:8];
                                if (cpu_wstrb[2]) data_array[req_index][23:16] <= cpu_wdata[23:16];
                                if (cpu_wstrb[3]) data_array[req_index][31:24] <= cpu_wdata[31:24];
                            end
                            2'b01: begin
                                if (cpu_wstrb[0]) data_array[req_index][39:32] <= cpu_wdata[7:0];
                                if (cpu_wstrb[1]) data_array[req_index][47:40] <= cpu_wdata[15:8];
                                if (cpu_wstrb[2]) data_array[req_index][55:48] <= cpu_wdata[23:16];
                                if (cpu_wstrb[3]) data_array[req_index][63:56] <= cpu_wdata[31:24];
                            end
                            2'b10: begin
                                if (cpu_wstrb[0]) data_array[req_index][71:64] <= cpu_wdata[7:0];
                                if (cpu_wstrb[1]) data_array[req_index][79:72] <= cpu_wdata[15:8];
                                if (cpu_wstrb[2]) data_array[req_index][87:80] <= cpu_wdata[23:16];
                                if (cpu_wstrb[3]) data_array[req_index][95:88] <= cpu_wdata[31:24];
                            end
                            2'b11: begin
                                if (cpu_wstrb[0]) data_array[req_index][103:96]  <= cpu_wdata[7:0];
                                if (cpu_wstrb[1]) data_array[req_index][111:104] <= cpu_wdata[15:8];
                                if (cpu_wstrb[2]) data_array[req_index][119:112] <= cpu_wdata[23:16];
                                if (cpu_wstrb[3]) data_array[req_index][127:120] <= cpu_wdata[31:24];
                            end
                        endcase
                    end
                end

                WB_REQ, MEM_REQ: begin
                    burst_counter <= 2'b00;
                end

                WB_DATA: begin
                    if (bus_ready) begin
                        burst_counter <= burst_counter + 1'b1;
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
                    data_array[req_index]  <= line_buffer;
                    tag_array[req_index]   <= req_tag;
                    valid_array[req_index] <= 1'b1;
                    dirty_array[req_index] <= 1'b0; // Freshly fetched block is clean
                end
            endcase
        end
    end

endmodule